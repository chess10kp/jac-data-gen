"""LadybugDB/ladybug#650 — Column segment tree split candidate walk.

Hand-rolled parent/child segment pointers for oversized chunk detection and
descendant closure before CSR node-group segmentation lands.
"""

from __future__ import annotations

from collections import deque


class SegmentStore:
    def __init__(self) -> None:
        self._segments: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._size: dict[str, int] = {}


def load_segments(
    segments: list[str],
    parent_edges: list[tuple[str, str]],
    sizes: list[tuple[str, int]],
) -> SegmentStore:
    store = SegmentStore()
    for sid in segments:
        store._segments.add(sid)
        store._parent[sid] = None
        store._children.setdefault(sid, [])
        store._size[sid] = 0
    for parent, child in parent_edges:
        if parent in store._segments and child in store._segments:
            store._parent[child] = parent
            store._children.setdefault(parent, []).append(child)
    for sid, sz in sizes:
        if sid in store._segments:
            store._size[sid] = sz
    return store


def segment_closure(store: SegmentStore, seg_id: str) -> list[str]:
    if seg_id not in store._segments:
        return []
    seen: set[str] = {seg_id}
    q: deque[str] = deque(store._children.get(seg_id, []))
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for ch in store._children.get(cur, []):
            if ch not in seen:
                q.append(ch)
    return sorted(seen)


def oversized_segments(store: SegmentStore, max_size: int) -> list[str]:
    return sorted(sid for sid in store._segments if store._size.get(sid, 0) > max_size)


def split_candidates(store: SegmentStore, seg_id: str) -> list[str]:
    if seg_id not in store._segments:
        return []
    hits: list[str] = []
    for desc in segment_closure(store, seg_id):
        if store._size.get(desc, 0) > store._size.get(seg_id, 0):
            hits.append(desc)
    return sorted(hits)
