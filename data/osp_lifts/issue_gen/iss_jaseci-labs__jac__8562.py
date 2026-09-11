"""jaseci-labs/jac#8562 — cyclic graph traversal requires explicit visit dedup."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set


class CyclicGraph:
    """Directed graph backed by an adjacency dict of neighbor lists."""

    def __init__(self) -> None:
        self._adj: Dict[str, List[str]] = {}

    def add_edge(self, src: str, dst: str) -> None:
        self._adj.setdefault(src, []).append(dst)
        self._adj.setdefault(dst, [])

    def neighbors(self, node: str) -> List[str]:
        return list(self._adj.get(node, []))

    def nodes(self) -> List[str]:
        return sorted(self._adj.keys())


def count_reachable_dfs(graph: CyclicGraph, start: str) -> int:
    """DFS with visited-set; must terminate on cycles."""
    visited: Set[str] = set()

    def walk(node: str) -> None:
        if node in visited:
            return
        visited.add(node)
        for nb in graph.neighbors(node):
            walk(nb)

    if start not in graph.nodes():
        return 0
    walk(start)
    return len(visited)


def count_reachable_bfs(graph: CyclicGraph, start: str) -> int:
    """BFS with visited-set; queue may re-enqueue but visited filters."""
    if start not in graph.nodes():
        return 0
    visited: Set[str] = set()
    queue: deque[str] = deque([start])
    while queue:
        node = queue.popleft()
        if node in visited:
            continue
        visited.add(node)
        for nb in graph.neighbors(node):
            if nb not in visited:
                queue.append(nb)
    return len(visited)


def reachable_nodes(graph: CyclicGraph, start: str) -> List[str]:
    """Return sorted reachable node ids (order unspecified in semantics)."""
    if start not in graph.nodes():
        return []
    visited: Set[str] = set()
    queue: deque[str] = deque([start])
    while queue:
        node = queue.popleft()
        if node in visited:
            continue
        visited.add(node)
        for nb in graph.neighbors(node):
            queue.append(nb)
    return sorted(visited)
