"""dasomel/narwhal#110 — CMDB service topology blast-radius traversal."""

from __future__ import annotations

from collections import deque


def _rev_adj(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    rev: dict[str, list[str]] = {}
    for consumer, upstream in edges:
        rev.setdefault(upstream, []).append(consumer)
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


def upstream_chain(service: str, depends_on: dict[str, str]) -> list[str]:
    chain: list[str] = []
    cur: str | None = service
    seen: set[str] = set()
    while cur is not None and cur not in seen:
        seen.add(cur)
        chain.append(cur)
        cur = depends_on.get(cur)
    return chain
