"""Workflow DAG build ordering and reachability. Source: zackees/zccache#1099."""

from __future__ import annotations

from collections import deque


def _adj(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    adj: dict[str, list[str]] = {}
    nodes: set[str] = set()
    for a, b in edges:
        nodes.add(a)
        nodes.add(b)
        adj.setdefault(a, []).append(b)
        adj.setdefault(b, [])
    return adj


def _indegree(edges: list[tuple[str, str]]) -> dict[str, int]:
    indeg: dict[str, int] = {}
    for a, b in edges:
        indeg.setdefault(a, 0)
        indeg[b] = indeg.get(b, 0) + 1
    for a, _ in edges:
        indeg.setdefault(a, 0)
    return indeg


def build_order(edges: list[tuple[str, str]]) -> list[str]:
    adj = _adj(edges)
    indeg = _indegree(edges)
    q: deque[str] = deque(sorted(n for n, d in indeg.items() if d == 0))
    order: list[str] = []
    while q:
        node = q.popleft()
        order.append(node)
        for nxt in sorted(adj.get(node, [])):
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                q.append(nxt)
    if len(order) != len(indeg):
        return []
    return order


def workflow_reachable(start: str, edges: list[tuple[str, str]]) -> list[str]:
    adj = _adj(edges)
    if start not in adj:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([start])
    while q:
        node = q.popleft()
        if node in seen:
            continue
        seen.add(node)
        for nxt in adj.get(node, []):
            if nxt not in seen:
                q.append(nxt)
    return sorted(seen)
