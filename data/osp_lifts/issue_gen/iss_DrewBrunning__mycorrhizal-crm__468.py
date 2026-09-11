"""DrewBrunning/mycorrhizal-crm#468 — multi-hop CRM relationship reach."""

from __future__ import annotations

from collections import deque


class CrmGraph:
    def __init__(self) -> None:
        self._contacts: set[str] = set()
        self._related: dict[str, list[str]] = {}


def load_crm(
    contacts: list[str],
    relation_edges: list[tuple[str, str]],
) -> CrmGraph:
    g = CrmGraph()
    for cid in contacts:
        g._contacts.add(cid)
        g._related.setdefault(cid, [])
    for a, b in relation_edges:
        if a in g._contacts and b in g._contacts:
            g._related.setdefault(a, []).append(b)
            g._related.setdefault(b, g._related.get(b, []))
    return g


def reachable_contacts(store: CrmGraph, start: str) -> list[str]:
    if start not in store._contacts:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        for nxt in store._related.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def relationship_hops(store: CrmGraph, start: str) -> int:
    if start not in store._contacts:
        return -1
    depth: dict[str, int] = {start: 0}
    queue: deque[str] = deque([start])
    best = 0
    while queue:
        cur = queue.popleft()
        for nxt in store._related.get(cur, []):
            nd = depth[cur] + 1
            if nd > best:
                best = nd
            if nxt not in depth or nd > depth[nxt]:
                depth[nxt] = nd
                queue.append(nxt)
    return best


def hub_neighbors(store: CrmGraph, hub_id: str) -> list[str]:
    if hub_id not in store._contacts:
        return []
    return sorted(store._related.get(hub_id, []))
