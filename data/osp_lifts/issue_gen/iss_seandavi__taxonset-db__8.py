"""seandavi/taxonset-db#8 — taxonomy subtree queries via parent-child lineage."""

from __future__ import annotations

from collections import deque


class TaxonStore:
    def __init__(self) -> None:
        self._taxa: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._ranks: dict[str, str] = {}


def load_taxonomy(
    taxa: list[tuple[str, str]],
    parent_edges: list[tuple[str, str]],
) -> TaxonStore:
    store = TaxonStore()
    for tid, rank in taxa:
        store._taxa.add(tid)
        store._ranks[tid] = rank
        store._parent[tid] = None
        store._children.setdefault(tid, [])
    for parent, child in parent_edges:
        if parent in store._taxa and child in store._taxa:
            store._parent[child] = parent
            store._children.setdefault(parent, []).append(child)
    return store


def _descendant_bfs(store: TaxonStore, root: str) -> list[str]:
    if root not in store._taxa:
        return []
    q: deque[str] = deque([root])
    claimed: set[str] = set()
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for ch in sorted(store._children.get(cur, [])):
            if ch not in claimed:
                q.append(ch)
    return hits


def descendants(store: TaxonStore, tax_id: str) -> list[str]:
    return sorted(_descendant_bfs(store, tax_id))


def ancestor_chain(store: TaxonStore, tax_id: str) -> list[str]:
    if tax_id not in store._taxa:
        return []
    chain = [tax_id]
    claimed: set[str] = {tax_id}
    cur = tax_id
    while True:
        parent = store._parent.get(cur)
        if parent is None or parent in claimed:
            break
        claimed.add(parent)
        chain.append(parent)
        cur = parent
    return chain


def taxa_by_rank(store: TaxonStore, root_id: str, rank: str) -> list[str]:
    return sorted([t for t in _descendant_bfs(store, root_id) if store._ranks.get(t) == rank])
