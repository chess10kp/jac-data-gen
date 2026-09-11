"""Kinetic639/coreframe-boilerplate#95 — category hierarchy via recursive CTE (pre-OSP)."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Optional, Set


class CategoryTree:
    """Hand-rolled parent/child adjacency for build-time category hierarchy."""

    def __init__(self) -> None:
        self._nodes: Set[str] = set()
        self._children: Dict[str, List[str]] = {}
        self._parent: Dict[str, Optional[str]] = {}

    def add_category(self, cat_id: str) -> None:
        if cat_id in self._nodes:
            raise ValueError(f"duplicate category: {cat_id}")
        self._nodes.add(cat_id)
        self._children.setdefault(cat_id, [])
        self._parent[cat_id] = None

    def add_child(self, parent_id: str, child_id: str) -> None:
        if parent_id not in self._nodes or child_id not in self._nodes:
            raise KeyError("unknown category id")
        self._parent[child_id] = parent_id
        self._children[parent_id].append(child_id)

    def _recursive_cte_descendants(self, seed: str) -> List[str]:
        settled: Set[str] = set()
        order: List[str] = []
        work: deque[str] = deque([seed])
        while work:
            node = work.popleft()
            if node in settled:
                continue
            settled.add(node)
            order.append(node)
            for nxt in sorted(self._children.get(node, [])):
                if nxt not in settled:
                    work.append(nxt)
        return order

    def descendants(self, cat_id: str) -> List[str]:
        if cat_id not in self._nodes:
            return []
        return sorted(set(self._recursive_cte_descendants(cat_id)))

    def ancestors(self, cat_id: str) -> List[str]:
        if cat_id not in self._nodes:
            return []
        out: List[str] = []
        cur: Optional[str] = self._parent.get(cat_id)
        while cur is not None:
            out.append(cur)
            cur = self._parent.get(cur)
        return sorted(out)

    def find_cycle(self) -> List[str]:
        WHITE, GRAY, BLACK = 0, 1, 2
        color: Dict[str, int] = {n: WHITE for n in self._nodes}
        stack: List[str] = []

        def dfs(u: str) -> List[str]:
            color[u] = GRAY
            stack.append(u)
            for v in self._children.get(u, []):
                if color[v] == GRAY and v in stack:
                    i = stack.index(v)
                    return stack[i:] + [v]
                if color[v] == WHITE:
                    found = dfs(v)
                    if found:
                        return found
            stack.pop()
            color[u] = BLACK
            return []

        for n in sorted(self._nodes):
            if color[n] == WHITE:
                cyc = dfs(n)
                if cyc:
                    return cyc
        return []
