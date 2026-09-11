"""Bounded compiler artifact cache with reverse dependency invalidation.

Source: EffortlessMetrics/perl-lsp-swarm#7946.
"""

from __future__ import annotations

from collections import deque


def _fwd_adj(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    adj: dict[str, list[str]] = {}
    for src, dst in edges:
        adj.setdefault(src, []).append(dst)
        adj.setdefault(dst, [])
    return adj


def _rev_adj(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    rev: dict[str, list[str]] = {}
    for src, dst in edges:
        rev.setdefault(dst, []).append(src)
        rev.setdefault(src, [])
    return rev


def artifact_closure(artifact: str, edges: list[tuple[str, str]]) -> list[str]:
    adj = _fwd_adj(edges)
    if artifact not in adj:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([artifact])
    while q:
        node = q.popleft()
        if node in seen:
            continue
        seen.add(node)
        for nxt in adj.get(node, []):
            if nxt not in seen:
                q.append(nxt)
    return sorted(seen)


def dependent_closure(artifact: str, edges: list[tuple[str, str]]) -> list[str]:
    rev = _rev_adj(edges)
    if artifact not in rev:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([artifact])
    while q:
        node = q.popleft()
        if node in seen:
            continue
        seen.add(node)
        for nxt in rev.get(node, []):
            if nxt not in seen:
                q.append(nxt)
    return sorted(seen)


def cache_lookup(key: str, cache: dict[str, str]) -> str | None:
    return cache.get(key)


def invalidate_artifact(
    artifact: str,
    edges: list[tuple[str, str]],
    cache: dict[str, str],
) -> list[str]:
    victims = dependent_closure(artifact, edges)
    for key in victims:
        cache.pop(key, None)
    return victims
