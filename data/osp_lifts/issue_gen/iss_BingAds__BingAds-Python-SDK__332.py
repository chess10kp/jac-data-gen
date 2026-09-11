"""Bulk row dependency resolver — BingAds/BingAds-Python-SDK#332.

Hand-rolled adjacency + Kahn-style queue for parent/child bulk rows.
"""
from __future__ import annotations

from collections import deque
from typing import Dict, List, Set


class BulkProcessor:
    def __init__(self) -> None:
        self._rows: Dict[str, str] = {}
        self._parent: Dict[str, str | None] = {}
        self._children: Dict[str, List[str]] = {}

    def register_row(self, row_id: str, payload: str, parent_id: str | None = None) -> None:
        self._rows[row_id] = payload
        self._parent[row_id] = parent_id
        self._children.setdefault(row_id, [])
        if parent_id is not None:
            self._children.setdefault(parent_id, []).append(row_id)

    def processing_order(self) -> List[str]:
        indeg: Dict[str, int] = {rid: 0 for rid in self._rows}
        for rid, par in self._parent.items():
            if par is not None and par in self._rows:
                indeg[rid] += 1
        q: deque[str] = deque(sorted(r for r, d in indeg.items() if d == 0))
        out: List[str] = []
        while q:
            cur = q.popleft()
            out.append(cur)
            for ch in sorted(self._children.get(cur, [])):
                indeg[ch] -= 1
                if indeg[ch] == 0:
                    q.append(ch)
        return out

    def unreachable(self) -> List[str]:
        ordered = set(self.processing_order())
        return sorted(r for r in self._rows if r not in ordered)

    def read_simulated(self, row_id: str) -> str:
        if row_id not in self._rows:
            raise KeyError(row_id)
        return self._rows[row_id]


def build_processor() -> BulkProcessor:
    return BulkProcessor()
