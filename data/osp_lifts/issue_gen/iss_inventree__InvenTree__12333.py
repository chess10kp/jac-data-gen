"""inventree/InvenTree#12333 — MPTT-style parent/child tree traversal."""

from __future__ import annotations


class MpttStore:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}


def load_mptt_tree(
    nodes: list[str],
    parent_edges: list[tuple[str, str | None]],
) -> MpttStore:
    store = MpttStore()
    for nid in nodes:
        store._nodes.add(nid)
        store._children.setdefault(nid, [])
    for nid, par in parent_edges:
        if nid not in store._nodes:
            continue
        store._parent[nid] = par
        if par is not None and par in store._nodes:
            store._children.setdefault(par, []).append(nid)
    return store


def _walk_descendants(store: MpttStore, root: str, acc: set[str]) -> None:
    for ch in sorted(store._children.get(root, [])):
        if ch in acc:
            continue
        acc.add(ch)
        _walk_descendants(store, ch, acc)


def get_descendants(store: MpttStore, node_id: str) -> list[str]:
    if node_id not in store._nodes:
        return []
    acc: set[str] = {node_id}
    _walk_descendants(store, node_id, acc)
    return sorted(acc)


def get_ancestors(store: MpttStore, node_id: str) -> list[str]:
    if node_id not in store._nodes:
        return []
    chain: list[str] = []
    seen: set[str] = {node_id}
    cur = node_id
    while True:
        parent = store._parent.get(cur)
        if parent is None or parent in seen:
            break
        seen.add(parent)
        chain.append(parent)
        cur = parent
    return sorted(chain)


def subtree_size(store: MpttStore, node_id: str) -> int:
    return len(get_descendants(store, node_id))
