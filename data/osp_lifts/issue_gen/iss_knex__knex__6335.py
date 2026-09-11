"""knex/knex#6335 — WITH RECURSIVE closure with cycle detection."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple


class RecursiveGraph:
    def __init__(self) -> None:
        self._nodes: Set[str] = set()
        self._adj: Dict[str, List[str]] = {}

    def add(self, node_id: str) -> None:
        self._nodes.add(node_id)
        self._adj.setdefault(node_id, [])

    def edge(self, src: str, dst: str) -> None:
        if src not in self._nodes or dst not in self._nodes:
            raise KeyError("unknown node")
        self._adj[src].append(dst)

    def closure(self, seed: str) -> List[str] | None:
        if seed not in self._nodes:
            return []
        seen: Set[str] = set()
        order: List[str] = []
        work: deque[str] = deque([seed])
        while work:
            u = work.popleft()
            if u in seen:
                return None  # cycle — recursive CTE would diverge
            seen.add(u)
            order.append(u)
            for v in sorted(self._adj.get(u, [])):
                if v not in seen:
                    work.append(v)
        return sorted(order)

    def has_cycle(self) -> bool:
        for n in sorted(self._nodes):
            if self.closure(n) is None:
                return True
        return False


def load_graph(nodes: List[str], edges: List[Tuple[str, str]]) -> RecursiveGraph:
    g = RecursiveGraph()
    for n in nodes:
        g.add(n)
    for s, d in edges:
        g.edge(s, d)
    return g
