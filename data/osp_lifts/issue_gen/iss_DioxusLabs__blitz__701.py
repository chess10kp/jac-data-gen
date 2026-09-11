"""DioxusLabs/blitz#701 — inline SVG dependency DAG load order."""

from __future__ import annotations
from collections import deque
from typing import Dict, List, Set

class SvgDag:
    def __init__(self) -> None:
        self.edges: Dict[str, List[str]] = {}
        self.names: Dict[str, str] = {}

    def node(self, nid: str, name: str) -> None:
        self.names[nid] = name
        self.edges.setdefault(nid, [])

    def use(self, from_id: str, to_id: str) -> None:
        self.edges.setdefault(from_id, []).append(to_id)

    def load_order(self, root_id: str) -> List[str]:
        seen: Set[str] = set()
        order: List[str] = []
        q: deque[str] = deque([root_id])
        while q:
            cur = q.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            for dep in self.edges.get(cur, []):
                q.append(dep)
            order.append(cur)
        return order

    def reachable(self, root_id: str) -> List[str]:
        return sorted(set(self.load_order(root_id)))
