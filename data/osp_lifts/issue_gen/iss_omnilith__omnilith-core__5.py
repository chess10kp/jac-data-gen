"""omnilith/omnilith-core#5 — basic dependency relations over entities."""
from __future__ import annotations

from collections import deque
from typing import Dict, List, Set


class RelationGraph:
    def __init__(self) -> None:
        self._entities: Set[str] = set()
        self._adj: Dict[str, List[str]] = {}

    def add_entity(self, eid: str) -> None:
        if eid in self._entities:
            return
        self._entities.add(eid)
        self._adj[eid] = []

    def link(self, src: str, dst: str) -> None:
        if src not in self._entities or dst not in self._entities:
            return
        self._adj[src].append(dst)

    def reachable_from(self, start: str) -> List[str]:
        if start not in self._entities:
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
            for nxt in self._adj.get(cur, []):
                if nxt not in seen:
                    q.append(nxt)
        return out

    def has_cycle(self) -> bool:
        WHITE, GRAY, BLACK = 0, 1, 2
        color: Dict[str, int] = {e: WHITE for e in self._entities}

        def dfs(u: str) -> bool:
            color[u] = GRAY
            for v in self._adj.get(u, []):
                if color[v] == GRAY:
                    return True
                if color[v] == WHITE and dfs(v):
                    return True
            color[u] = BLACK
            return False

        for eid in sorted(self._entities):
            if color[eid] == WHITE and dfs(eid):
                return True
        return False


def build_graph() -> RelationGraph:
    return RelationGraph()
