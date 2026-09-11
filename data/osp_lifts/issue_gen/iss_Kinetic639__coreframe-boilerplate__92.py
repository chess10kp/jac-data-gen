"""Kinetic639/coreframe-boilerplate#92 — Category tree descent and level refresh.

Hand-rolled parent_id recursion and N+1 child walks before SQL recursive CTE
RPC replaces isDescendant and updateChildrenLevels.
"""

from __future__ import annotations


class CategoryStore:
    def __init__(self) -> None:
        self._categories: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._level: dict[str, int] = {}


def load_categories(
    categories: list[str],
    parent_edges: list[tuple[str, str]],
    levels: list[tuple[str, int]],
) -> CategoryStore:
    store = CategoryStore()
    for cid in categories:
        store._categories.add(cid)
        store._parent[cid] = None
        store._children.setdefault(cid, [])
        store._level[cid] = 0
    for parent, child in parent_edges:
        if parent in store._categories and child in store._categories:
            store._parent[child] = parent
            store._children.setdefault(parent, []).append(child)
    for cid, lvl in levels:
        if cid in store._categories:
            store._level[cid] = lvl
    return store


def _walk_ancestors(store: CategoryStore, target_id: str) -> list[str]:
    chain: list[str] = []
    cur: str | None = target_id
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store._parent.get(cur)
    return chain


def is_descendant(store: CategoryStore, target_id: str, category_id: str) -> bool:
    if target_id not in store._categories or category_id not in store._categories:
        return False
    return category_id in _walk_ancestors(store, target_id)


def update_children_levels(
    store: CategoryStore,
    parent_id: str,
    parent_level: int,
) -> list[str]:
    if parent_id not in store._categories:
        return []
    updated: list[str] = []
    stack: list[tuple[str, int]] = [(parent_id, parent_level)]
    while stack:
        cur, lvl = stack.pop()
        for ch in sorted(store._children.get(cur, [])):
            new_lvl = lvl + 1
            if store._level.get(ch) != new_lvl:
                store._level[ch] = new_lvl
                updated.append(ch)
            stack.append((ch, new_lvl))
    return sorted(updated)


def get_ancestors(store: CategoryStore, cat_id: str) -> list[str]:
    if cat_id not in store._categories:
        return []
    chain = _walk_ancestors(store, cat_id)
    chain.pop(0)
    return chain
