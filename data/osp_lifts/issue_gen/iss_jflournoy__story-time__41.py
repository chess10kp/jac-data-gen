"""jflournoy/story-time#41 — outline beat tree CRUD with recursive descendant deletion."""

from __future__ import annotations

from collections import deque

STATUS_OUTLINE = "outline"
REL_REQUIRES = "requires"


class OutlineBeat:
    def __init__(
        self,
        beat_id: str,
        session_id: str,
        position: int,
        depth: int,
        content: str,
        status: str,
        deleted: bool = False,
    ) -> None:
        self.beat_id = beat_id
        self.session_id = session_id
        self.position = position
        self.depth = depth
        self.content = content
        self.status = status
        self.deleted = deleted


class OutlineStore:
    def __init__(self) -> None:
        self.beats: dict[str, OutlineBeat] = {}
        self._children: dict[str, list[str]] = {}
        self._parent: dict[str, str | None] = {}
        self._world_refs: dict[str, list[tuple[str, str]]] = {}


def _tree_walk_ids(start_id: str, store: OutlineStore) -> list[str]:
    visited: set[str] = set()
    order: list[str] = []
    stack: list[str] = [start_id]
    while stack:
        cur = stack.pop()
        if cur in visited:
            continue
        visited.add(cur)
        order.append(cur)
        kids = sorted(store._children.get(cur, []))
        i = len(kids) - 1
        while i >= 0:
            stack.append(kids[i])
            i -= 1
    return order


def fresh_outline_store() -> OutlineStore:
    return OutlineStore()


def register_beat(
    beat_id: str,
    session_id: str,
    position: int,
    depth: int,
    content: str,
    status: str,
    store: OutlineStore | None = None,
    parent_id: str | None = None,
) -> OutlineStore:
    s = store
    if s is None:
        s = fresh_outline_store()
    if beat_id in s.beats:
        raise ValueError("duplicate beat id")
    nd = OutlineBeat(
        beat_id=beat_id,
        session_id=session_id,
        position=position,
        depth=depth,
        content=content,
        status=status,
    )
    s.beats[beat_id] = nd
    s._children.setdefault(beat_id, [])
    s._parent[beat_id] = None
    s._world_refs.setdefault(beat_id, [])
    if parent_id is not None:
        link_child(parent_id, beat_id, s)
    return s


def link_child(parent_id: str, child_id: str, store: OutlineStore) -> None:
    if parent_id not in store.beats or child_id not in store.beats:
        raise KeyError("unknown beat id")
    if parent_id == child_id:
        return
    if store._parent.get(child_id) is not None:
        raise ValueError("child already has parent")
    kids = store._children.setdefault(parent_id, [])
    if child_id not in kids:
        kids.append(child_id)
        kids.sort()
    store._parent[child_id] = parent_id


def get_descendant_ids(beat_id: str, store: OutlineStore) -> list[str]:
    if beat_id not in store.beats:
        raise KeyError(beat_id)
    reach: list[str] = []
    for bid in _tree_walk_ids(beat_id, store):
        if bid != beat_id and not store.beats[bid].deleted:
            reach.append(bid)
    return sorted(reach)


def list_session_beats(session_id: str, store: OutlineStore) -> list[str]:
    rows: list[tuple[int, int, str]] = []
    for bid, nd in store.beats.items():
        if nd.session_id == session_id and not nd.deleted:
            rows.append((nd.depth, nd.position, bid))
    rows.sort()
    return [bid for _, _, bid in rows]


def delete_beat_cascade(beat_id: str, store: OutlineStore) -> list[str]:
    if beat_id not in store.beats:
        raise KeyError(beat_id)
    start = store.beats[beat_id]
    if start.deleted:
        return []
    deleted: list[str] = []
    for bid in _tree_walk_ids(beat_id, store):
        nd = store.beats.get(bid)
        if nd is not None and not nd.deleted:
            nd.deleted = True
            deleted.append(bid)
    return sorted(deleted)


def add_world_ref(beat_id: str, fact_id: str, relationship: str, store: OutlineStore) -> None:
    if beat_id not in store.beats:
        raise KeyError("unknown beat id")
    refs = store._world_refs.setdefault(beat_id, [])
    refs.append((fact_id, relationship))


def world_refs_for_beat(beat_id: str, store: OutlineStore) -> list[tuple[str, str]]:
    if beat_id not in store.beats:
        raise KeyError(beat_id)
    return sorted(store._world_refs.get(beat_id, []))
