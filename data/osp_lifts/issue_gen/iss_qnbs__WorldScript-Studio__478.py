"""qnbs/WorldScript-Studio#478 — PWA offline manifest require-graph closure.

Hand-rolled adjacency dict + deque BFS + visited-set closure for service-worker
precache bundles. register_asset names a routable asset; require(asset, needs)
records that asset must pull needs offline; offline_closure(root) returns all
transitive requirements (sorted).
"""

from __future__ import annotations

from collections import deque


class OfflineManifest:
    """Mutable offline asset require index; built fresh per test fixture."""

    def __init__(self) -> None:
        self._adj: dict[str, list[str]] = {}
        self._nodes: set[str] = set()

    def register_asset(self, asset_id: str) -> None:
        if asset_id not in self._nodes:
            self._nodes.add(asset_id)
            self._adj.setdefault(asset_id, [])

    def require(self, asset: str, needs: str) -> None:
        self.register_asset(asset)
        self.register_asset(needs)
        self._adj[asset].append(needs)

    def offline_closure(self, root: str) -> list[str]:
        if root not in self._nodes:
            return []
        visited: set[str] = {root}
        queue: deque[str] = deque(self._adj.get(root, []))
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
