"""netkeep80/pjson#38 — Persistent $ref resolution with cycle-safe bounds."""

from __future__ import annotations


class RefStore:
    # Node registry plus ref->target pointer map for chained resolution.
    def __init__(self) -> None:
        self._nodes: dict[str, str | None] = {}
        self._refs: dict[str, str] = {}


def load_refs(
    nodes: list[tuple[str, str | None]],
    ref_edges: list[tuple[str, str]],
) -> RefStore:
    store = RefStore()
    for nid, value in nodes:
        store._nodes[nid] = value
    for ref_id, target_id in ref_edges:
        if ref_id in store._nodes:
            store._refs[ref_id] = target_id
    return store


def resolve(store: RefStore, ref_id: str, max_depth: int) -> str | None:
    if ref_id not in store._nodes:
        return None
    seen: set[str] = set()
    cur = ref_id
    depth = 0
    while cur in store._refs:
        if cur in seen:
            return None
        if depth >= max_depth:
            return None
        seen.add(cur)
        nxt = store._refs[cur]
        if nxt not in store._nodes:
            return None
        cur = nxt
        depth += 1
    return store._nodes.get(cur)


def is_cyclic_ref(store: RefStore, ref_id: str) -> bool:
    return resolve(store, ref_id, max_depth=32) is None and ref_id in store._refs


def deref_chain(store: RefStore, ref_id: str) -> list[str]:
    chain: list[str] = []
    seen: set[str] = set()
    cur = ref_id
    while cur in store._refs:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        nxt = store._refs[cur]
        if nxt not in store._nodes:
            break
        cur = nxt
    return chain
