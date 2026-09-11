"""dunay2/dvt#2594 — bounded Substrait card pipeline (pre-OSP).

Cards are language-neutral transformation units; depends() forms a DAG.
Hand-rolled adjacency dicts + Kahn topological sort + DFS downstream closure.
"""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set

class CycleError(ValueError):
    """Raised when the card dependency graph contains a cycle."""


class CardPipeline:
    """Mutable card dependency graph for transformation ordering."""

    def __init__(self) -> None:
        self._cards: Set[str] = set()
        self._deps: Dict[str, List[str]] = {}
        self._rev: Dict[str, List[str]] = {}

    def add_card(self, card_id: str) -> None:
        self._cards.add(card_id)
        self._deps.setdefault(card_id, [])
        self._rev.setdefault(card_id, [])

    def depends(self, card: str, dep: str) -> None:
        if card not in self._cards or dep not in self._cards:
            raise KeyError("unknown card id")
        self._deps[card].append(dep)
        self._rev[dep].append(card)

    def _find_cycle(self) -> List[str]:
        WHITE, GRAY, BLACK = 0, 1, 2
        color: Dict[str, int] = {n: WHITE for n in self._cards}
        stack: List[str] = []

        def dfs(u: str) -> List[str]:
            color[u] = GRAY
            stack.append(u)
            for v in self._deps.get(u, []):
                if color[v] == WHITE:
                    found = dfs(v)
                    if found:
                        return found
                elif color[v] == GRAY and v in stack:
                    i = stack.index(v)
                    return stack[i:] + [v]
            stack.pop()
            color[u] = BLACK
            return []

        for n in sorted(self._cards):
            if color[n] == WHITE:
                cyc = dfs(n)
                if cyc:
                    return cyc
        return []

    def linearize(self) -> List[str]:
        cyc = self._find_cycle()
        if cyc:
            raise CycleError("cycle in card pipeline")
        indeg: Dict[str, int] = {n: 0 for n in self._cards}
        for card, preds in self._deps.items():
            for p in preds:
                indeg[card] += 1
        q: deque[str] = deque(sorted(n for n, d in indeg.items() if d == 0))
        out: List[str] = []
        while q:
            u = q.popleft()
            out.append(u)
            for v in sorted(self._rev.get(u, [])):
                indeg[v] -= 1
                if indeg[v] == 0:
                    q.append(v)
        if len(out) != len(self._cards):
            raise CycleError("cycle in card pipeline")
        return out

    def downstream(self, card_id: str) -> List[str]:
        if card_id not in self._cards:
            return []
        seen: Set[str] = set()
        stack: List[str] = [card_id]
        while stack:
            u = stack.pop()
            if u in seen:
                continue
            seen.add(u)
            for v in self._rev.get(u, []):
                if v not in seen:
                    stack.append(v)
        return sorted(seen)
