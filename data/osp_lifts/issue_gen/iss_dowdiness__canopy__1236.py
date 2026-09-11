"""Cut B′ responsibility and lifetime ledger for projection publishers.

Source: dowdiness/canopy#1236
"""

from __future__ import annotations

from collections import deque


def _children(owns: list[tuple[str, str]]) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for parent, child in owns:
        out.setdefault(parent, []).append(child)
    for key in out:
        out[key].sort()
    return out


def _published(publishes: list[tuple[str, str]]) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for pub, proj in publishes:
        out.setdefault(pub, []).append(proj)
    for key in out:
        out[key].sort()
    return out


def _depends(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for src, dst in edges:
        out.setdefault(src, []).append(dst)
    for key in out:
        out[key].sort()
    return out


def responsibility_ledger(
    seed: str,
    owns: list[tuple[str, str]],
    publishes: list[tuple[str, str]],
) -> dict[str, str]:
    # BFS over shell ownership with publish cascades into projections.
    kids = _children(owns)
    pubs = _published(publishes)
    ledger: dict[str, str] = {seed: seed}
    seen: set[str] = {seed}
    q: deque[str] = deque([seed])
    while q:
        owner = q.popleft()
        for child in kids.get(owner, []):
            if child not in ledger:
                ledger[child] = owner
            if child not in seen:
                seen.add(child)
                q.append(child)
        for proj in pubs.get(owner, []):
            if proj not in ledger:
                ledger[proj] = owner
            if proj not in seen:
                seen.add(proj)
                q.append(proj)
    return ledger


def lifetime_owners(
    projection: str,
    chain: list[tuple[str, str]],
) -> list[str]:
    # Walk parent pointers upward from a projection shell chain.
    parent_of: dict[str, str] = {}
    for parent, child in chain:
        parent_of[child] = parent
    owners: list[str] = []
    cur = projection
    while cur in parent_of:
        cur = parent_of[cur]
        owners.append(cur)
    return sorted(set(owners))


def cut_b_prime_closure(
    start: str,
    edges: list[tuple[str, str]],
) -> list[str]:
    # Downstream workflow closure for the Cut B′ reachable slice.
    adj = _depends(edges)
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
