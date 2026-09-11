"""Stewie-pixel/claude-with-leetcode#520 — Remove Methods From Project reachability.

Hand-rolled adjacency list + iterative DFS for suspicious method closure and
external incoming-edge boundary check (LeetCode 3310).
"""

from __future__ import annotations


def remaining_methods(
    n: int,
    k: int,
    invocations: list[list[int]],
) -> list[int]:
    graph: dict[int, list[int]] = {i: [] for i in range(n)}
    for a, b in invocations:
        graph[a].append(b)

    suspicious = [False] * n
    stack = [k]
    suspicious[k] = True
    while stack:
        u = stack.pop()
        for v in graph[u]:
            if not suspicious[v]:
                suspicious[v] = True
                stack.append(v)

    for a, b in invocations:
        if not suspicious[a] and suspicious[b]:
            return list(range(n))

    return [i for i in range(n) if not suspicious[i]]
