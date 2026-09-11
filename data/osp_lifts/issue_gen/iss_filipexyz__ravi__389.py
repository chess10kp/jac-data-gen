"""Dependency gates and cycle detection for workflow eligibility. Source: filipexyz/ravi#389."""

from __future__ import annotations

from collections import deque


def _adj(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    adj: dict[str, list[str]] = {}
    for a, b in edges:
        adj.setdefault(a, []).append(b)
        adj.setdefault(b, [])
    return adj


def eligible_targets(
    nodes: list[str],
    edges: list[tuple[str, str]],
    ready: set[str],
) -> list[str]:
    preds: dict[str, list[str]] = {n: [] for n in nodes}
    for a, b in edges:
        if b in preds:
            preds[b].append(a)
    out: list[str] = []
    for n in sorted(nodes):
        reqs = preds.get(n, [])
        if all(r in ready for r in reqs):
            out.append(n)
    return out


def find_cycle_nodes(edges: list[tuple[str, str]]) -> list[str]:
    adj = _adj(edges)
    WHITE, GRAY, BLACK = 0, 1, 2
    color: dict[str, int] = {n: WHITE for n in adj}
    in_cycle: set[str] = set()

    def dfs(node: str) -> None:
        color[node] = GRAY
        for nxt in adj.get(node, []):
            if color[nxt] == GRAY:
                in_cycle.add(node)
                in_cycle.add(nxt)
            elif color[nxt] == WHITE:
                dfs(nxt)
                if nxt in in_cycle:
                    in_cycle.add(node)
        color[node] = BLACK

    for n in sorted(adj):
        if color[n] == WHITE:
            dfs(n)
    return sorted(in_cycle)
