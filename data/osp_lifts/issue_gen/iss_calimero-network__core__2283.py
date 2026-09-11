"""calimero-network/core#2283 — leave_namespace cascade through descendant membership scopes."""

from __future__ import annotations

from collections import deque


class NamespaceStore:
    def __init__(self) -> None:
        self._groups: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._members: dict[str, set[str]] = {}


def load_namespace(
    groups: list[str],
    parent_edges: list[tuple[str, str]],
    members: list[tuple[str, str]],
) -> NamespaceStore:
    ns = NamespaceStore()
    for gid in groups:
        ns._groups.add(gid)
        ns._parent[gid] = None
        ns._children.setdefault(gid, [])
        ns._members.setdefault(gid, set())
    for parent, child in parent_edges:
        if parent in ns._groups and child in ns._groups:
            ns._parent[child] = parent
            ns._children.setdefault(parent, []).append(child)
    for gid, user in members:
        if gid in ns._groups:
            ns._members.setdefault(gid, set()).add(user)
    return ns


def _subtree_groups(ns: NamespaceStore, root_id: str) -> list[str]:
    if root_id not in ns._groups:
        return []
    q: deque[str] = deque([root_id])
    claimed: set[str] = set()
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for ch in sorted(ns._children.get(cur, [])):
            if ch not in claimed:
                q.append(ch)
    return hits


def scopes_for_member(ns: NamespaceStore, user: str, root_id: str) -> list[str]:
    if root_id not in ns._groups:
        return []
    scopes: list[str] = []
    for gid in _subtree_groups(ns, root_id):
        if user in ns._members.get(gid, set()):
            scopes.append(gid)
    return sorted(scopes)


def leave_namespace(ns: NamespaceStore, user: str, root_id: str) -> list[str]:
    targets = scopes_for_member(ns, user, root_id)
    removed: list[str] = []
    for gid in targets:
        if user in ns._members.get(gid, set()):
            ns._members[gid].discard(user)
            removed.append(gid)
    return sorted(removed)


def member_groups(ns: NamespaceStore, user: str) -> list[str]:
    out = [gid for gid in sorted(ns._groups) if user in ns._members.get(gid, set())]
    return out


def orphaned_memberships(ns: NamespaceStore, user: str, root_id: str) -> list[str]:
    # subgroup membership without ancestor membership on root chain
    root_scopes = set(_subtree_groups(ns, root_id))
    bad: list[str] = []
    for gid in sorted(root_scopes):
        if user in ns._members.get(gid, set()) and user not in ns._members.get(root_id, set()):
            bad.append(gid)
    return bad
