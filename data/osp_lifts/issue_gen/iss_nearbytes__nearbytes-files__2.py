"""nearbytes/nearbytes-files#2 — Materialized directory parent-child tree.

Event-log fold paths are stored as parent pointers with children adjacency;
recursive ascent collects ancestor segments for breadcrumb replay.
"""

from __future__ import annotations


class DirStore:
    def __init__(self) -> None:
        self.parent_of: dict[str, str | None] = {}
        self.children_of: dict[str, list[str]] = {}


def load_directory_tree(segments: list[list[str]]) -> DirStore:
    store = DirStore()
    for parts in segments:
        parent: str | None = None
        for seg in parts:
            if seg not in store.parent_of:
                store.parent_of[seg] = parent
                store.children_of.setdefault(seg, [])
                if parent is not None:
                    store.children_of.setdefault(parent, []).append(seg)
            parent = seg
    return store


def _ancestors(store: DirStore, node_id: str) -> list[str]:
    chain: list[str] = []
    cur: str | None = node_id
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store.parent_of.get(cur)
    chain.reverse()
    return chain


def breadcrumb(store: DirStore, node_id: str) -> list[str]:
    if node_id not in store.parent_of:
        return []
    return _ancestors(store, node_id)


def subtree_ids(store: DirStore, root_id: str) -> list[str]:
    if root_id not in store.parent_of:
        return []
    stack = [root_id]
    seen: set[str] = set()
    out: list[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in sorted(store.children_of.get(cur, [])):
            stack.append(ch)
    return sorted(out)
