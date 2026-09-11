"""Compiler stage invalidation and provider cache. Source: EffortlessMetrics/perl-lsp-swarm#5216."""

from __future__ import annotations

from collections import deque
from typing import Any


def invalidate_stages(changed: str, deps: dict[str, list[str]]) -> list[str]:
    adj = {k: list(v) for k, v in deps.items()}
    for k in deps:
        adj.setdefault(k, [])
    seen: set[str] = set()
    q: deque[str] = deque([changed])
    order: list[str] = []
    while q:
        stage = q.popleft()
        if stage in seen:
            continue
        seen.add(stage)
        order.append(stage)
        for nxt in adj.get(stage, []):
            if nxt not in seen:
                q.append(nxt)
    return order


def memo_ancestors(node: str, parent: dict[str, str]) -> list[str]:
    cache: dict[str, list[str]] = {}
    stack: list[str] = [node]

    def walk(n: str) -> list[str]:
        if n in cache:
            return cache[n]
        chain: list[str] = []
        cur = n
        while cur in parent:
            cur = parent[cur]
            chain.append(cur)
        cache[n] = chain
        return chain

    while stack:
        walk(stack.pop())
    return cache.get(node, [])


def provider_utility_hit(cache: dict[str, Any], key: str) -> tuple[bool, Any]:
    if key in cache:
        return True, cache[key]
    return False, None
