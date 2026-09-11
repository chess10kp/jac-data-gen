"""Synthetic before-code for kristtst01/codetrace#47 — topological sort with DAG checks."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set


class CycleError(ValueError):
    pass


class TaskDag:
    # Hand-rolled adjacency: task -> tasks it depends on (must run first)
    def __init__(self) -> None:
        self._deps: Dict[str, List[str]] = {}
        self._rev: Dict[str, List[str]] = {}

    def add_task(self, task_id: str) -> None:
        self._deps.setdefault(task_id, [])
        self._rev.setdefault(task_id, [])

    def add_dependency(self, task_id: str, depends_on: str) -> None:
        if task_id not in self._deps or depends_on not in self._deps:
            raise KeyError("unknown task")
        if task_id not in self._deps[depends_on]:
            self._deps[depends_on].append(task_id)
        if task_id not in self._rev[task_id]:
            self._rev[task_id].append(depends_on)

    def has_cycle(self) -> bool:
        visited: Set[str] = set()
        stack: Set[str] = set()

        def dfs(node: str) -> bool:
            if node in stack:
                return True
            if node in visited:
                return False
            visited.add(node)
            stack.add(node)
            for nxt in self._deps.get(node, []):
                if dfs(nxt):
                    return True
            stack.remove(node)
            return False

        return any(dfs(n) for n in self._deps)

    def topological_order(self) -> List[str]:
        if self.has_cycle():
            raise CycleError("cycle")
        indeg = {t: 0 for t in self._deps}
        for t, outs in self._deps.items():
            for o in outs:
                indeg[o] = indeg.get(o, 0) + 1
        q: deque[str] = deque(sorted(t for t, d in indeg.items() if d == 0))
        out: List[str] = []
        while q:
            cur = q.popleft()
            out.append(cur)
            for nxt in sorted(self._deps.get(cur, [])):
                indeg[nxt] -= 1
                if indeg[nxt] == 0:
                    q.append(nxt)
        if len(out) != len(self._deps):
            raise CycleError("cycle")
        return out

    def ancestors(self, task_id: str) -> List[str]:
        if task_id not in self._deps:
            raise KeyError("unknown task")
        seen: Set[str] = set()
        q: deque[str] = deque(self._rev.get(task_id, []))
        while q:
            cur = q.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            q.extend(self._rev.get(cur, []))
        return sorted(seen)
