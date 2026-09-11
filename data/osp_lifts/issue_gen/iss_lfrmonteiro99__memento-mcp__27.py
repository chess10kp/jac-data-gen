"""Typed-edge memory knowledge graph — lfrmonteiro99/memento-mcp#27."""
from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple


class MemoryGraph:
    def __init__(self) -> None:
        self._labels: Dict[str, str] = {}
        self._adj: Dict[str, List[Tuple[str, str]]] = {}

    def add_memory(self, mid: str, label: str) -> None:
        if mid not in self._labels:
            self._labels[mid] = label
            self._adj[mid] = []

    def add_link(self, src: str, dst: str, kind: str = "related") -> None:
        if src not in self._labels or dst not in self._labels:
            return
        self._adj[src].append((dst, kind))

    def reachable_from(self, start: str) -> List[str]:
        if start not in self._labels:
            return []
        seen: Set[str] = set()
        q: deque[str] = deque([start])
        out: List[str] = []
        while q:
            cur = q.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            for nxt, _ in self._adj.get(cur, []):
                if nxt not in seen:
                    q.append(nxt)
        return out

    def has_cycle(self) -> bool:
        WHITE, GRAY, BLACK = 0, 1, 2
        color: Dict[str, int] = {m: WHITE for m in self._labels}

        def dfs(u: str) -> bool:
            color[u] = GRAY
            for v, _ in self._adj.get(u, []):
                if color[v] == GRAY:
                    return True
                if color[v] == WHITE and dfs(v):
                    return True
            color[u] = BLACK
            return False

        for node in sorted(self._labels):
            if color[node] == WHITE and dfs(node):
                return True
        return False


def build_graph() -> MemoryGraph:
    return MemoryGraph()
