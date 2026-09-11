"""WITH-clause name resolution — Dtronix/Quarry#331.

Shared SQL parser rejects WITH statements; column resolution needs the
transitive closure of named CTE references (manual adjacency + BFS).
"""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set


class CteRegistry:
    def __init__(self) -> None:
        self._names: Set[str] = set()
        self._refs: Dict[str, List[str]] = {}

    def register_with(self, name: str, refs: List[str] | None = None) -> None:
        self._names.add(name)
        self._refs.setdefault(name, [])
        if refs:
            self._refs[name].extend(refs)

    def reachable_ctes(self, start: str) -> List[str]:
        if start not in self._names:
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
            for nxt in self._refs.get(cur, []):
                if nxt in self._names and nxt not in seen:
                    q.append(nxt)
        return out

    def column_context(self, query_name: str) -> List[str]:
        return sorted(self.reachable_ctes(query_name))

    def has_unknown_ref(self, name: str) -> bool:
        for src, refs in self._refs.items():
            for r in refs:
                if r not in self._names:
                    return True
        return False


def build_registry() -> CteRegistry:
    return CteRegistry()
