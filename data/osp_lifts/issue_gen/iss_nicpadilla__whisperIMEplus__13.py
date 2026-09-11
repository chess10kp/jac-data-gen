"""nicpadilla/whisperIMEplus#13 — fork hardening roadmap implementation order.

Hand-rolled adjacency + Kahn topological queue with phase/priority tie-break (pre-OSP).
"""

from __future__ import annotations

from collections import defaultdict, deque
from typing import Dict, List, Set


class CycleError(ValueError):
    """Raised when fork roadmap dependency graph contains a cycle."""


class RoadmapStore:
    """Mutable fork-hardening roadmap keyed by issue id with phase priority."""

    def __init__(self) -> None:
        self._nodes: Set[str] = set()
        self._deps: Dict[str, List[str]] = defaultdict(list)
        self._rev: Dict[str, List[str]] = defaultdict(list)
        self._phase: Dict[str, int] = {}
        self._priority: Dict[str, int] = {}

    def add_item(self, iid: str, phase: int, priority: int) -> None:
        if iid in self._nodes:
            raise ValueError(f"duplicate roadmap item: {iid}")
        self._nodes.add(iid)
        self._phase[iid] = phase
        self._priority[iid] = priority
        self._deps.setdefault(iid, [])
        self._rev.setdefault(iid, [])

    def add_depends(self, item: str, dep: str) -> None:
        if item not in self._nodes or dep not in self._nodes:
            raise KeyError("unknown roadmap item id")
        self._deps[item].append(dep)
        self._rev[dep].append(item)

    def find_cycle(self) -> List[str]:
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

    def implementation_order(self) -> List[str]:
        if self.find_cycle():
            raise CycleError("cycle in fork roadmap")
        indeg: Dict[str, int] = {n: 0 for n in self._nodes}
        for item, preds in self._deps.items():
            for p in preds:
                indeg[item] += 1

        def sort_key(iid: str) -> tuple:
            return (self._phase[iid], -self._priority[iid], iid)

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
            raise CycleError("cycle in fork roadmap")
        return out

    def reachable_from(self, start: str) -> List[str]:
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
