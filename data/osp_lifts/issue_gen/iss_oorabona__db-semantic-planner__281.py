"""Cycle-safe path expansion (ARRAY-path CTE analogue) — oorabona/db-semantic-planner#281."""
from __future__ import annotations
from typing import Dict, List, Set

class PathGraph:
    def __init__(self) -> None:
        self._adj: Dict[str, List[str]] = {}

    def add_edge(self, src: str, dst: str) -> None:
        self._adj.setdefault(src, [])
        if dst not in self._adj[src]:
            self._adj[src].append(dst)
        self._adj.setdefault(dst, [])

    def safe_paths(self, start: str) -> List[List[str]]:
        if start not in self._adj and start not in {d for xs in self._adj.values() for d in xs}:
            return []
        paths: List[List[str]] = []
        stack: List[tuple[str, List[str]]] = [(start, [start])]
        while stack:
            node, path = stack.pop()
            nxts = self._adj.get(node, [])
            if not nxts:
                paths.append(path)
                continue
            for nxt in nxts:
                if nxt in path:
                    continue
                stack.append((nxt, path + [nxt]))
        return sorted(paths)

    def has_cycle(self) -> bool:
        color: Dict[str, int] = {}
        def dfs(u: str, trail: Set[str]) -> bool:
            if u in trail:
                return True
            trail.add(u)
            for v in self._adj.get(u, []):
                if dfs(v, set(trail)):
                    return True
            return False
        for n in sorted(self._adj):
            if dfs(n, set()):
                return True
        return False

def build_path_graph() -> PathGraph:
    return PathGraph()
