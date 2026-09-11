"""Hand-rolled graph traversals. Source: sudosf/leetcode#122."""

from __future__ import annotations

from collections import deque
from typing import DefaultDict


def _adjacency(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    adj: DefaultDict[str, list[str]] = DefaultDict(list)
    nodes: set[str] = set()
    for a, b in edges:
        nodes.add(a)
        nodes.add(b)
        adj[a].append(b)
    for n in nodes:
        adj.setdefault(n, [])
    return dict(adj)


def bfs_order(edges: list[tuple[str, str]], start: str) -> list[str]:
    adj = _adjacency(edges)
    if start not in adj:
        return []
    seen: set[str] = set()
    order: list[str] = []
    q: deque[str] = deque([start])
    while q:
        node = q.popleft()
        if node in seen:
            continue
        seen.add(node)
        order.append(node)
        for nxt in adj.get(node, []):
            if nxt not in seen:
                q.append(nxt)
    return order


def dfs_preorder(edges: list[tuple[str, str]], start: str) -> list[str]:
    adj = _adjacency(edges)
    if start not in adj:
        return []
    seen: set[str] = set()
    order: list[str] = []
    stack: list[str] = [start]
    while stack:
        node = stack.pop()
        if node in seen:
            continue
        seen.add(node)
        order.append(node)
        for nxt in reversed(adj.get(node, [])):
            if nxt not in seen:
                stack.append(nxt)
    return order


def reachable(edges: list[tuple[str, str]], start: str) -> list[str]:
    return sorted(set(bfs_order(edges, start)))
