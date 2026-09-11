"""jurrebuunk/ticket-cmdb#2 — Nested CMDB items for hierarchical impact analysis."""

from __future__ import annotations

from collections import deque


class CmdbStore:
    # Hand-rolled parent pointers + child adjacency (recursive-CTE stand-in).
    def __init__(self) -> None:
        self._items: set[str] = set()
        self._parent: dict[str, str] = {}
        self._children: dict[str, list[str]] = {}


def load_cmdb(
    items: list[str],
    contains_edges: list[tuple[str, str]],
) -> CmdbStore:
    g = CmdbStore()
    for iid in items:
        g._items.add(iid)
        g._children.setdefault(iid, [])
    for parent, child in contains_edges:
        if parent not in g._items or child not in g._items:
            continue
        g._parent[child] = parent
        g._children.setdefault(parent, []).append(child)
        g._children.setdefault(child, g._children.get(child, []))
    return g


def _recursive_collect(store: CmdbStore, root: str, acc: set[str]) -> None:
    # WITH RECURSIVE body over the adjacency dict.
    for ch in sorted(store._children.get(root, [])):
        if ch in acc:
            continue
        acc.add(ch)
        _recursive_collect(store, ch, acc)


def impact_radius(store: CmdbStore, item_id: str) -> list[str]:
    if item_id not in store._items:
        return []
    seen: set[str] = {item_id}
    work: deque[str] = deque([item_id])
    while work:
        cur = work.popleft()
        for ch in store._children.get(cur, []):
            if ch not in seen:
                seen.add(ch)
                work.append(ch)
    closure: set[str] = set(seen)
    _recursive_collect(store, item_id, closure)
    return sorted(closure)


def ancestor_chain(store: CmdbStore, item_id: str) -> list[str]:
    if item_id not in store._items:
        return []
    chain: list[str] = [item_id]
    claimed: set[str] = {item_id}
    cur = item_id
    while True:
        parent = store._parent.get(cur)
        if parent is None or parent in claimed:
            break
        claimed.add(parent)
        chain.append(parent)
        cur = parent
    return chain
