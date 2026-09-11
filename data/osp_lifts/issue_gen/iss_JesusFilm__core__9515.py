"""JesusFilm/core#9515 — Video availableLanguages upward recompute with cascade."""

from __future__ import annotations


class VideoStore:
    def __init__(self) -> None:
        self.parent_of: dict[str, str | None] = {}
        self.children_of: dict[str, list[str]] = {}
        self.own_languages: dict[str, list[str]] = {}
        self.available: dict[str, list[str]] = {}


def load_video_store(
    videos: list[str],
    parent_map: dict[str, str | None],
    own_langs: dict[str, list[str]],
) -> VideoStore:
    s = VideoStore()
    for vid in videos:
        s.parent_of[vid] = parent_map.get(vid)
        s.children_of.setdefault(vid, [])
        s.own_languages[vid] = sorted(own_langs.get(vid, []))
        s.available[vid] = []
    for vid, parent in parent_map.items():
        if parent is not None and parent in s.parent_of:
            s.children_of.setdefault(parent, []).append(vid)
    for vid in videos:
        s.available[vid] = _compute_available(s, vid)
    return s


def _compute_available(
    store: VideoStore,
    video_id: str,
    visiting: set[str] | None = None,
) -> list[str]:
    if visiting is None:
        visiting = set()
    if video_id in visiting:
        raise ValueError("cycle detected")
    visiting.add(video_id)
    langs: set[str] = set(store.own_languages.get(video_id, []))
    for ch in store.children_of.get(video_id, []):
        langs.update(_compute_available(store, ch, visiting))
    visiting.remove(video_id)
    return sorted(langs)


def recompute_upward(store: VideoStore, start_id: str) -> list[str]:
    if start_id not in store.parent_of:
        return []
    changed: list[str] = []
    cur: str | None = start_id
    while cur is not None:
        new_val = _compute_available(store, cur)
        if store.available.get(cur, []) != new_val:
            store.available[cur] = new_val
            changed.append(cur)
        cur = store.parent_of.get(cur)
    return sorted(changed)


def remove_child(store: VideoStore, parent_id: str, child_id: str) -> list[str]:
    kids = store.children_of.get(parent_id, [])
    if child_id in kids:
        kids.remove(child_id)
        store.parent_of[child_id] = None
    return recompute_upward(store, parent_id)


def get_available(store: VideoStore, video_id: str) -> list[str]:
    return list(store.available.get(video_id, []))
