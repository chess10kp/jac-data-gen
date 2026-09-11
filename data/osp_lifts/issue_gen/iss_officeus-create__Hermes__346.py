"""officeus-create/Hermes#346 — SEO12 revenue-first master backlog execution order.

Hand-rolled adjacency + Kahn topological queue with revenue/tid tie-break (pre-OSP).
"""

from __future__ import annotations

from collections import defaultdict, deque
from typing import Dict, List, Set


class CycleError(ValueError):
    """Raised when backlog dependency graph contains a cycle."""


class BacklogStore:
    """Mutable master backlog keyed by task id with revenue priority."""

    def __init__(self) -> None:
        self._nodes: Set[str] = set()
        self._deps: Dict[str, List[str]] = defaultdict(list)
        self._rev: Dict[str, List[str]] = defaultdict(list)
        self._revenue: Dict[str, int] = {}

    def add_task(self, tid: str, revenue: int) -> None:
        if tid in self._nodes:
            raise ValueError(f"duplicate task: {tid}")
        self._nodes.add(tid)
        self._revenue[tid] = revenue
        self._deps.setdefault(tid, [])
        self._rev.setdefault(tid, [])

    def add_depends(self, t: str, dep: str) -> None:
        if t not in self._nodes or dep not in self._nodes:
            raise KeyError("unknown task id")
        self._deps[t].append(dep)
        self._rev[dep].append(t)

    def find_cycle(self) -> List[str]:
        """Return one dependency cycle as id list, or [] if acyclic."""
        WHITE, GRAY, BLACK = 0, 1, 2
        color: Dict[str, int] = {n: WHITE for n in self._nodes}
        stack: List[str] = []
        found: List[str] = []

        def dfs(u: str) -> None:
            color[u] = GRAY
            stack.append(u)
            for v in self._deps.get(u, []):
                if color[v] == GRAY:
                    if v in stack:
                        i = stack.index(v)
                        found[:] = stack[i:] + [v]
                    return
                if color[v] == WHITE:
                    dfs(v)
                    if found:
                        return
            stack.pop()
            color[u] = BLACK

        for n in sorted(self._nodes):
            if color[n] == WHITE:
                dfs(n)
                if found:
                    return found
        return []

    def execution_order(self) -> List[str]:
        """Topological order; among ready tasks higher revenue first, then tid."""
        if self.find_cycle():
            raise CycleError("cycle in backlog dag")
        indeg: Dict[str, int] = {n: 0 for n in self._nodes}
        for t, preds in self._deps.items():
            for p in preds:
                indeg[t] += 1

        def sort_key(tid: str) -> tuple:
            return (-self._revenue[tid], tid)

        q: deque[str] = deque(
            sorted([n for n, d in indeg.items() if d == 0], key=sort_key)
        )
        out: List[str] = []
        while q:
            u = q.popleft()
            out.append(u)
            for v in sorted(self._rev.get(u, []), key=sort_key):
                indeg[v] -= 1
                if indeg[v] == 0:
                    q.append(v)
        if len(out) != len(self._nodes):
            raise CycleError("cycle in backlog dag")
        return out

    def reachable_from(self, start: str) -> List[str]:
        """DFS closure along reverse edges (downstream dependents)."""
        if start not in self._nodes:
            return []
        claimed: Set[str] = set()
        out: List[str] = []
        stack: List[str] = [start]
        while stack:
            u = stack.pop()
            if u in claimed:
                continue
            claimed.add(u)
            out.append(u)
            for v in self._rev.get(u, []):
                if v not in claimed:
                    stack.append(v)
        return sorted(out)
