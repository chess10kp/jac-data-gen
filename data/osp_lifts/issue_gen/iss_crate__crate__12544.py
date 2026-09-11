"""Recursive CTE expansion with cycle safety. Source: crate/crate#12544."""

from __future__ import annotations

from collections import deque


def recursive_cte_expand(
    seed: str,
    edges: list[tuple[str, str]],
) -> list[str]:
    adj: dict[str, list[str]] = {}
    for a, b in edges:
        adj.setdefault(a, []).append(b)
    settled: set[str] = set()
    work: deque[str] = deque([seed])
    order: list[str] = []
    while work:
        node = work.popleft()
        if node in settled:
            continue
        settled.add(node)
        order.append(node)
        for nxt in sorted(adj.get(node, [])):
            if nxt not in settled:
                work.append(nxt)
    return order


def cte_reachable(seed: str, edges: list[tuple[str, str]]) -> list[str]:
    return sorted(set(recursive_cte_expand(seed, edges)))


def is_recursive_safe(edges: list[tuple[str, str]]) -> bool:
    adj: dict[str, list[str]] = {}
    nodes: set[str] = set()
    for a, b in edges:
        nodes.add(a)
        nodes.add(b)
        adj.setdefault(a, []).append(b)
    color: dict[str, int] = {}

    def dfs(n: str) -> bool:
        color[n] = 1
        for c in adj.get(n, []):
            st = color.get(c, 0)
            if st == 1:
                return False
            if st == 0 and not dfs(c):
                return False
        color[n] = 2
        return True

    for n in nodes:
        if color.get(n, 0) == 0 and not dfs(n):
            return False
    return True
