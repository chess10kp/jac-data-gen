"""VrUaCom/dmc-rengine-cpp#100 — Nested archive container traversal."""

from __future__ import annotations


class ArchiveStore:
    # Parent pointers + children lists for nested PAC/NBZ volumes.
    def __init__(self) -> None:
        self._entries: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._kind: dict[str, str] = {}


def load_volumes(
    entries: list[tuple[str, str]],
    contains: list[tuple[str, str]],
) -> ArchiveStore:
    store = ArchiveStore()
    for eid, kind in entries:
        store._entries.add(eid)
        store._kind[eid] = kind
        store._parent[eid] = None
        store._children.setdefault(eid, [])
    for parent, child in contains:
        if parent in store._entries and child in store._entries:
            store._parent[child] = parent
            store._children.setdefault(parent, []).append(child)
            store._children.setdefault(child, store._children.get(child, []))
    return store


def _descend(store: ArchiveStore, root: str, acc: list[str], seen: set[str]) -> None:
    for ch in store._children.get(root, []):
        if ch in seen:
            continue
        seen.add(ch)
        acc.append(ch)
        _descend(store, ch, acc, seen)


def nested_children(store: ArchiveStore, volume_id: str) -> list[str]:
    if volume_id not in store._entries:
        return []
    out: list[str] = []
    seen: set[str] = {volume_id}
    stack: list[str] = list(store._children.get(volume_id, []))
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in store._children.get(cur, []):
            stack.append(ch)
    extra: list[str] = []
    _descend(store, volume_id, extra, set(seen))
    merged = sorted(set(out) | set(extra))
    return merged


def materialization_path(store: ArchiveStore, entry_id: str) -> list[str]:
    if entry_id not in store._entries:
        return []
    chain: list[str] = [entry_id]
    claimed: set[str] = {entry_id}
    cur = entry_id
    while True:
        parent = store._parent.get(cur)
        if parent is None or parent in claimed:
            break
        claimed.add(parent)
        chain.append(parent)
        cur = parent
    return list(reversed(chain))


def entry_kind(store: ArchiveStore, entry_id: str) -> str | None:
    return store._kind.get(entry_id)
