"""Arkeon-Technologies/arkeon#6 — graph traversal primitives for filtered neighborhood queries.

Hand-rolled adjacency index, recursive depth expansion, and deque BFS shortest-path.
"""

from __future__ import annotations

from collections import deque


class TraversalGraph:
    """Mutable labeled graph; fresh instance per test."""

    def __init__(self) -> None:
        self._adj: dict[str, list[tuple[str, str]]] = {}
        self._nodes: set[str] = set()

    def link(self, a: str, b: str, kind: str) -> None:
        for vid in (a, b):
            if vid not in self._nodes:
                self._nodes.add(vid)
                self._adj.setdefault(vid, [])
        self._adj[a].append((b, kind))

    def _descend(
        self,
        cur: str,
        remaining: int,
        allowed: set[str],
        seen: set[str],
        out: list[str],
    ) -> None:
        # Recursive CTE-style filtered neighborhood expansion.
        if remaining <= 0:
            return
        for nxt, edge_kind in self._adj.get(cur, []):
            if edge_kind not in allowed or nxt in seen:
                continue
            seen.add(nxt)
            out.append(nxt)
            self._descend(nxt, remaining - 1, allowed, seen, out)

    def traverse(self, start: str, depth: int, allowed_kinds: set[str]) -> list[str]:
        if start not in self._nodes:
            return []
        seen: set[str] = {start}
        hits: list[str] = []
        self._descend(start, depth, allowed_kinds, seen, hits)
        return sorted(hits)

    def shortest_path(
        self,
        src: str,
        dst: str,
        max_depth: int,
        allowed_kinds: set[str],
    ) -> list[str] | None:
        if src not in self._nodes or dst not in self._nodes:
            return None
        if src == dst:
            return [src]
        parent: dict[str, str] = {}
        claimed: set[str] = {src}
        queue: deque[tuple[str, int]] = deque([(src, 0)])
        while queue:
            cur, d = queue.popleft()
            if cur == dst:
                path: list[str] = []
                node: str | None = dst
                while node is not None:
                    path.append(node)
                    node = parent.get(node) if node != src else None
                return list(reversed(path))
            if d >= max_depth:
                continue
            for nxt, edge_kind in self._adj.get(cur, []):
                if edge_kind not in allowed_kinds or nxt in claimed:
                    continue
                claimed.add(nxt)
                parent[nxt] = cur
                queue.append((nxt, d + 1))
        return None
