"""azaharizaman/nexus#135 — backoffice organizational hierarchy."""

from __future__ import annotations

from collections import deque


class OrgStore:
    def __init__(self) -> None:
        self._parent_of: dict[str, str | None] = {}
        self._children_of: dict[str, list[str]] = {}


def load_org_tree(
    orgs: list[tuple[str, str | None]],
) -> OrgStore:
    store = OrgStore()
    for oid, parent in orgs:
        if parent is not None and parent not in store._parent_of:
            raise KeyError("unknown parent organization")
        store._parent_of[oid] = parent
        store._children_of.setdefault(oid, [])
        if parent is not None:
            store._children_of.setdefault(parent, []).append(oid)
    return store


def ancestors_of(store: OrgStore, org_id: str) -> list[str]:
    if org_id not in store._parent_of:
        return []
    chain: list[str] = []
    cur: str | None = org_id
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store._parent_of.get(cur)
    return list(reversed(chain))


def descendants_of(store: OrgStore, root: str) -> list[str]:
    if root not in store._parent_of:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for child in sorted(store._children_of.get(cur, [])):
            if child not in seen:
                seen.add(child)
                queue.append(child)
    return sorted(seen)


def subtree_size(store: OrgStore, root: str) -> int:
    return len(descendants_of(store, root))


def leaf_orgs(store: OrgStore) -> list[str]:
    out: list[str] = []
    for oid in sorted(store._parent_of):
        if not store._children_of.get(oid, []):
            out.append(oid)
    return out
