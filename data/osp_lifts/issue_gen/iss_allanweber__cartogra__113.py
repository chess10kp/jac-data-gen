"""allanweber/cartogra#113 — Blast radius over service dependency graph.

Hand-rolled adjacency + BFS queue + visited-set closure.
Downstream depends on upstream: add_dependency(upstream, downstream).
"""

from __future__ import annotations

from collections import deque


class BlastRadiusGraph:
    """Mutable dependency index built fresh per test fixture."""

    def __init__(self) -> None:
        self._adj: dict[str, list[str]] = {}
        self._nodes: set[str] = set()

    def add_dependency(self, upstream: str, downstream: str) -> None:
        if upstream not in self._nodes:
            self._nodes.add(upstream)
            self._adj.setdefault(upstream, [])
        if downstream not in self._nodes:
            self._nodes.add(downstream)
            self._adj.setdefault(downstream, [])
        self._adj[upstream].append(downstream)

    def blast_radius(self, origin: str) -> list[str]:
        if origin not in self._nodes:
            return []
        visited: set[str] = {origin}
        queue: deque[str] = deque(self._adj.get(origin, []))
        hits: list[str] = []
        while queue:
            cur = queue.popleft()
            if cur in visited:
                continue
            visited.add(cur)
            hits.append(cur)
            for nxt in self._adj.get(cur, []):
                if nxt not in visited:
                    queue.append(nxt)
        return sorted(hits)

    def upstream_of(self, sid: str) -> list[str]:
        if sid not in self._nodes:
            return []
        preds: list[str] = []
        for up, downs in self._adj.items():
            if sid in downs:
                preds.append(up)
        return sorted(preds)
