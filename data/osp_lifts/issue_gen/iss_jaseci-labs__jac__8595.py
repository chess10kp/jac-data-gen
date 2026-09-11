"""jaseci-labs/jac#8595 — page adjacency neighborhood instead of materializing whole graph."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple


class GraphView:
    """Adjacency dict with paged neighbor reads and folded reachability."""

    def __init__(self) -> None:
        self._nodes: Set[str] = set()
        self._adj: Dict[str, List[str]] = {}

    def add_node(self, node_id: str) -> None:
        self._nodes.add(node_id)
        self._adj.setdefault(node_id, [])

    def link(self, src: str, dst: str) -> None:
        if src not in self._nodes or dst not in self._nodes:
            raise KeyError("unknown node id")
        self._adj[src].append(dst)

    def neighbors_page(self, node_id: str, offset: int, limit: int) -> List[str]:
        if node_id not in self._nodes:
            return []
        nbrs = sorted(self._adj.get(node_id, []))
        return nbrs[offset : offset + limit]

    def neighborhood_cost(self, node_id: str) -> int:
        # object-space cost proxy: size of sorted neighbor list
        if node_id not in self._nodes:
            return 0
        return len(self._adj.get(node_id, []))

    def reachable(self, seed: str) -> List[str]:
        if seed not in self._nodes:
            return []
        settled: Set[str] = set()
        work: deque[str] = deque([seed])
        while work:
            u = work.popleft()
            if u in settled:
                continue
            settled.add(u)
            for v in sorted(self._adj.get(u, [])):
                if v not in settled:
                    work.append(v)
        return sorted(settled)
