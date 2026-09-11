"""Zkrausman/pith#51 — deterministic portfolio planning scheduler."""

from __future__ import annotations

from collections import deque


class CycleError(Exception):
    pass


class PortfolioStore:
    def __init__(self) -> None:
        self._tickets: set[str] = set()
        self._blocks: dict[str, list[str]] = {}
        self._scores: dict[str, int] = {}


def load_portfolio(
    ticket_ids: list[str],
    block_edges: list[tuple[str, str]],
    scores: dict[str, int],
) -> PortfolioStore:
    store = PortfolioStore()
    for tid in ticket_ids:
        store._tickets.add(tid)
        store._blocks.setdefault(tid, [])
        store._scores[tid] = scores.get(tid, 0)
    for blocker, blocked in block_edges:
        if blocker in store._tickets and blocked in store._tickets:
            store._blocks.setdefault(blocked, []).append(blocker)
    return store


def _topo_layers(store: PortfolioStore) -> list[list[str]]:
    indegree: dict[str, int] = {t: 0 for t in store._tickets}
    rev: dict[str, list[str]] = {t: [] for t in store._tickets}
    for blocked, blockers in store._blocks.items():
        for b in blockers:
            indegree[blocked] += 1
            rev[b].append(blocked)
    layers: list[list[str]] = []
    visited: set[str] = set()
    ready = {t for t, d in indegree.items() if d == 0}
    while ready:
        layer = sorted(ready)
        layers.append(layer)
        next_ready: set[str] = set()
        for node in layer:
            visited.add(node)
            for other in rev.get(node, []):
                indegree[other] -= 1
                if indegree[other] == 0 and other not in visited:
                    next_ready.add(other)
        ready = next_ready
    if len(visited) != len(store._tickets):
        raise CycleError("hard dependency cycle")
    return layers


def planning_frontier(store: PortfolioStore, planned: list[str]) -> list[str]:
    done = set(planned)
    layers = _topo_layers(store)
    for layer in layers:
        frontier = [t for t in layer if t not in done]
        if frontier:
            return sorted(frontier)
    return []


def recommend_next(store: PortfolioStore, planned: list[str]) -> str | None:
    frontier = planning_frontier(store, planned)
    if not frontier:
        return None
    return max(frontier, key=lambda t: (store._scores.get(t, 0), t))


def downstream_reach(store: PortfolioStore, root: str) -> list[str]:
    if root not in store._tickets:
        return []
    rev: dict[str, list[str]] = {t: [] for t in store._tickets}
    for blocked, blockers in store._blocks.items():
        for b in blockers:
            rev[b].append(blocked)
    seen: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for nxt in rev.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)
