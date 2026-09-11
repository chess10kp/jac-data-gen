"""Blast-radius reverse traversal from a changed artifact. Source: MrNedimBoztepe/Shonkor#101."""

from __future__ import annotations

from collections import deque


def _rev_adj(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    rev: dict[str, list[str]] = {}
    for consumer, producer in edges:
        rev.setdefault(producer, []).append(consumer)
        rev.setdefault(consumer, [])
    return rev


def blast_radius(changed: str, edges: list[tuple[str, str]]) -> list[str]:
    rev = _rev_adj(edges)
    if changed not in rev:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([changed])
    while q:
        node = q.popleft()
        if node in seen:
            continue
        seen.add(node)
        for nxt in rev.get(node, []):
            if nxt not in seen:
                q.append(nxt)
    return sorted(seen)


def provenance_chain(node: str, parent_of: dict[str, str]) -> list[str]:
    chain: list[str] = []
    cur: str | None = node
    seen: set[str] = set()
    while cur is not None and cur not in seen:
        seen.add(cur)
        chain.append(cur)
        cur = parent_of.get(cur)
    return chain
