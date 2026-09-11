"""FraOri03/Lattice#202 — render cache invalidation downstream sweep."""

from __future__ import annotations

from collections import deque


class TimelineStore:
    def __init__(self) -> None:
        self._clips: set[str] = set()
        self._invalidates: dict[str, list[str]] = {}
        self._dirty: dict[str, bool] = {}


def load_timeline(
    clips: list[str],
    invalidates_edges: list[tuple[str, str]],
) -> TimelineStore:
    store = TimelineStore()
    for cid in clips:
        store._clips.add(cid)
        store._invalidates.setdefault(cid, [])
        store._dirty[cid] = False
    for src, dst in invalidates_edges:
        if src in store._clips and dst in store._clips:
            store._invalidates.setdefault(src, []).append(dst)
    return store


def invalidated_clips(store: TimelineStore, changed: list[str]) -> list[str]:
    seen: set[str] = set()
    queue: deque[str] = deque(ch for ch in changed if ch in store._clips)
    while queue:
        cur = queue.popleft()
        for nxt in store._invalidates.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def invalidate_cache(store: TimelineStore, clip_id: str) -> list[str]:
    if clip_id not in store._clips:
        return []
    swept = sorted([clip_id] + list(invalidated_clips(store, [clip_id])))
    for cid in swept:
        store._dirty[cid] = True
    return swept


def is_dirty(store: TimelineStore, clip_id: str) -> bool:
    if clip_id not in store._clips:
        return False
    return store._dirty.get(clip_id, False)
