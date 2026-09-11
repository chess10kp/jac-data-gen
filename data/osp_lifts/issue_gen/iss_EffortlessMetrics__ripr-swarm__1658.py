"""Bounded cargo-allow evidence relevance checks. Source: EffortlessMetrics/ripr-swarm#1658."""

from __future__ import annotations

from collections import deque


def evidence_reachable(
    seed: str,
    edges: list[tuple[str, str]],
    limit: int,
) -> list[str]:
    adj: dict[str, list[str]] = {}
    for a, b in edges:
        adj.setdefault(a, []).append(b)
    seen: set[str] = set()
    order: list[str] = []
    q: deque[str] = deque([seed])
    while q and len(order) < limit:
        node = q.popleft()
        if node in seen:
            continue
        seen.add(node)
        order.append(node)
        for nxt in sorted(adj.get(node, [])):
            if nxt not in seen:
                q.append(nxt)
    return order


def summarize_assertions(findings: list[str], limit: int) -> list[str]:
    return sorted(findings)[:limit]


def transitive_evidence(
    crate: str,
    depends: list[tuple[str, str]],
) -> list[str]:
    adj: dict[str, list[str]] = {}
    for a, b in depends:
        adj.setdefault(a, []).append(b)
    seen: set[str] = set()
    stack = [crate]
    while stack:
        n = stack.pop()
        if n in seen:
            continue
        seen.add(n)
        stack.extend(adj.get(n, []))
    return sorted(seen)
