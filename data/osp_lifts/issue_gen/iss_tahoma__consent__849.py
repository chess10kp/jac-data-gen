"""tahoma/consent#849 — SRFI 234 topological sorting."""

from __future__ import annotations
from collections import deque
from typing import Dict, List, Set

class TopoGraph:
    def __init__(self) -> None:
        self.succ: Dict[str, List[str]] = {}
        self.pred_count: Dict[str, int] = {}

    def add(self, n: str) -> None:
        self.succ.setdefault(n, [])
        self.pred_count.setdefault(n, 0)

    def edge(self, a: str, b: str) -> None:
        self.add(a); self.add(b)
        self.succ[a].append(b)
        self.pred_count[b] += 1

    def topsort(self) -> List[str]:
        q: deque[str] = deque(sorted([n for n, c in self.pred_count.items() if c == 0]))
        out: List[str] = []
        indeg = dict(self.pred_count)
        while q:
            n = q.popleft()
            out.append(n)
            for m in self.succ.get(n, []):
                indeg[m] -= 1
                if indeg[m] == 0:
                    q.append(m)
        if len(out) != len(indeg):
            raise ValueError("cycle")
        return out
