"""Tree parent-child with cycle detection. Source: prisma/prisma#4562."""

from __future__ import annotations

from collections import deque


def _children(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    kids: dict[str, list[str]] = {}
    nodes: set[str] = set()
    for p, c in edges:
        nodes.add(p)
        nodes.add(c)
        kids.setdefault(p, []).append(c)
    return kids


def children_of(node: str, edges: list[tuple[str, str]]) -> list[str]:
    return sorted(_children(edges).get(node, []))


def ancestors(node: str, edges: list[tuple[str, str]]) -> list[str]:
    parent: dict[str, str] = {}
    for p, c in edges:
        parent[c] = p
    chain: list[str] = []
    cur = node
    while cur in parent:
        cur = parent[cur]
        chain.append(cur)
    return chain


def is_acyclic(edges: list[tuple[str, str]]) -> bool:
    adj = _children(edges)
    color: dict[str, int] = {}

    def dfs(n: str) -> bool:
        color[n] = 1
        for c in adj.get(n, []):
            state = color.get(c, 0)
            if state == 1:
                return False
            if state == 0 and not dfs(c):
                return False
        color[n] = 2
        return True

    for n in adj:
        if color.get(n, 0) == 0 and not dfs(n):
            return False
    return True


def tree_closure(root: str, edges: list[tuple[str, str]]) -> list[str]:
    adj = _children(edges)
    seen: set[str] = set()
    q: deque[str] = deque([root])
    while q:
        n = q.popleft()
        if n in seen:
            continue
        seen.add(n)
        for c in adj.get(n, []):
            q.append(c)
    return sorted(seen)
