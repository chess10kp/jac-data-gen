"""MatRanc/VerticalTimeline2#25 — delete group, contents, and downstream dependents."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple


class TimelineStore:
    def __init__(self) -> None:
        self.groups: Set[str] = set()
        self.items: Set[str] = set()
        self.group_parent: Dict[str, str | None] = {}
        self.group_children: Dict[str, List[str]] = {}
        self.group_items: Dict[str, List[str]] = {}
        self.refs: Dict[str, List[str]] = {}
        self.rev_refs: Dict[str, List[str]] = {}


def load_timeline(
    groups: List[Tuple[str, str | None]],
    memberships: List[Tuple[str, str]],
    refs: List[Tuple[str, str]],
) -> TimelineStore:
    store = TimelineStore()
    for gid, par in groups:
        store.groups.add(gid)
        store.group_parent[gid] = par
        store.group_children.setdefault(gid, [])
        if par is not None:
            store.group_children.setdefault(par, []).append(gid)
    for grp_id, item_id in memberships:
        store.items.add(item_id)
        store.group_items.setdefault(grp_id, []).append(item_id)
        store.refs.setdefault(item_id, [])
        store.rev_refs.setdefault(item_id, [])
    for dep, need in refs:
        if dep not in store.items or need not in store.items:
            continue
        if need not in store.refs[dep]:
            store.refs[dep].append(need)
        if dep not in store.rev_refs[need]:
            store.rev_refs[need].append(dep)
    return store


def _group_subtree(store: TimelineStore, root_gid: str) -> List[str]:
    if root_gid not in store.groups:
        return []
    seen: Set[str] = set()
    stack = [root_gid]
    out: List[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in sorted(store.group_children.get(cur, [])):
            if ch not in seen:
                stack.append(ch)
    return out


def _items_in_groups(store: TimelineStore, group_ids: List[str]) -> List[str]:
    found: List[str] = []
    for gid in group_ids:
        for iid in sorted(store.group_items.get(gid, [])):
            if iid in store.items and iid not in found:
                found.append(iid)
    return found


def _dependent_items(store: TimelineStore, seeds: List[str]) -> List[str]:
    seen: Set[str] = set()
    q: deque[str] = deque()
    for sid in seeds:
        q.append(sid)
    while q:
        need = q.popleft()
        for dep in sorted(store.rev_refs.get(need, [])):
            if dep in store.items and dep not in seen:
                seen.add(dep)
                q.append(dep)
    return sorted(seen)


def delete_group(store: TimelineStore, group_id: str) -> List[str]:
    if group_id not in store.groups:
        return []
    subtree = _group_subtree(store, group_id)
    doomed: Set[str] = set(_items_in_groups(store, subtree))
    doomed.update(_dependent_items(store, sorted(doomed)))
    deleted = sorted(doomed)
    for iid in deleted:
        store.items.discard(iid)
        for need in list(store.refs.get(iid, [])):
            if iid in store.rev_refs.get(need, []):
                store.rev_refs[need].remove(iid)
        for dep in list(store.rev_refs.get(iid, [])):
            if iid in store.refs.get(dep, []):
                store.refs[dep].remove(iid)
        store.refs.pop(iid, None)
        store.rev_refs.pop(iid, None)
        for grp_items in store.group_items.values():
            if iid in grp_items:
                grp_items.remove(iid)
    for gid in subtree:
        store.groups.discard(gid)
        store.group_parent.pop(gid, None)
        store.group_children.pop(gid, None)
        store.group_items.pop(gid, None)
    for chs in store.group_children.values():
        for gid in subtree:
            if gid in chs:
                chs.remove(gid)
    return deleted


def active_items(store: TimelineStore) -> List[str]:
    return sorted(store.items)
