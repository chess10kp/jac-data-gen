"""Topological ordering for a task dependency DAG.

Issue: algoscope-hq/AlgoScope#838
https://github.com/algoscope-hq/AlgoScope/issues/838
"""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple


class CycleError(ValueError):
    pass


class TaskGraph:
    """Hand-rolled adjacency + indegree machinery for topo sort demos."""

    def __init__(self) -> None:
        self._nodes: Set[str] = set()
        self._adj: Dict[str, List[str]] = {}
        self._indeg: Dict[str, int] = {}

    def add_task(self, task_id: str) -> None:
        if task_id in self._nodes:
            return
        self._nodes.add(task_id)
        self._adj.setdefault(task_id, [])
        self._indeg.setdefault(task_id, 0)

    def add_dependency(self, before_id: str, after_id: str) -> None:
        # `before` must finish before `after`.
        self.add_task(before_id)
        self.add_task(after_id)
        self._adj[before_id].append(after_id)
        self._indeg[after_id] = self._indeg.get(after_id, 0) + 1

    def has_cycle(self) -> bool:
        try:
            self.topological_order_kahn()
        except CycleError:
            return True
        return False

    def topological_order_kahn(self) -> List[str]:
        indeg = dict(self._indeg)
        q: deque[str] = deque(sorted(n for n in self._nodes if indeg[n] == 0))
        out: List[str] = []
        while q:
            n = q.popleft()
            out.append(n)
            for m in sorted(self._adj.get(n, [])):
                indeg[m] -= 1
                if indeg[m] == 0:
                    q.append(m)
        if len(out) != len(self._nodes):
            raise CycleError("cycle detected")
        return out

    def topological_order_dfs(self) -> List[str]:
        visited: Set[str] = set()
        stack: Set[str] = set()
        order: List[str] = []

        def dfs(n: str) -> None:
            if n in stack:
                raise CycleError("cycle detected")
            if n in visited:
                return
            stack.add(n)
            for m in sorted(self._adj.get(n, [])):
                dfs(m)
            stack.remove(n)
            visited.add(n)
            order.append(n)

        for n in sorted(self._nodes):
            if n not in visited:
                dfs(n)
        order.reverse()
        return order

    def reachable_from(self, start_id: str) -> List[str]:
        if start_id not in self._nodes:
            return []
        seen: Set[str] = set()
        q: deque[str] = deque([start_id])
        while q:
            n = q.popleft()
            if n in seen:
                continue
            seen.add(n)
            for m in self._adj.get(n, []):
                q.append(m)
        seen.discard(start_id)
        return sorted(seen)
