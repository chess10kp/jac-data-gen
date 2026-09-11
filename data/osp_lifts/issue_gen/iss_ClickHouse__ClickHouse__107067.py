"""ClickHouse/ClickHouse#107067 — keyed recursive search with settled-set refutation."""

from __future__ import annotations

from collections import deque


class SearchGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._edges: dict[str, list[tuple[str, float]]] = {}


def load_search_graph(
    nodes: list[str],
    edges: list[tuple[str, str, float]],
) -> SearchGraph:
    g = SearchGraph()
    for n in nodes:
        g._nodes.add(n)
        g._edges.setdefault(n, [])
    for src, dst, weight in edges:
        if src in g._nodes and dst in g._nodes:
            g._edges.setdefault(src, []).append((dst, weight))
    return g


def shortest_costs(g: SearchGraph, start: str) -> dict[str, float]:
    if start not in g._nodes:
        return {}
    settled: dict[str, float] = {start: 0.0}
    frontier: deque[str] = deque([start])
    while frontier:
        cur = frontier.popleft()
        base = settled[cur]
        for nxt, w in g._edges.get(cur, []):
            cand = base + w
            old = settled.get(nxt)
            if old is None or cand < old:
                settled[nxt] = cand
                frontier.append(nxt)
    return dict(sorted(settled.items()))


def improved_nodes(g: SearchGraph, start: str) -> list[str]:
    costs = shortest_costs(g, start)
    return sorted(costs.keys())


def has_cycle(g: SearchGraph) -> bool:
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> bool:
        if node in stack:
            return True
        if node in visited:
            return False
        visited.add(node)
        stack.add(node)
        for nxt, _ in g._edges.get(node, []):
            if dfs(nxt):
                return True
        stack.remove(node)
        return False

    for n in sorted(g._nodes):
        if dfs(n):
            return True
    return False
