"""JesusFilm/core#9519 -- parent-variant create/cleanup via shared recompute."""

from __future__ import annotations

from collections import deque

class VideoStore:
    def __init__(self) -> None:
        self.videos: set[str] = set()
        self.parent: dict[str, str | None] = {}
        self.children: dict[str, list[str]] = {}
        self.available: dict[str, set[str]] = {}  # video -> languages
        self.container_label: dict[str, str] = {}

def make_store() -> VideoStore:
    return VideoStore()

def add_video(store: VideoStore, vid: str, parent: str | None, label: str, langs: set[str]) -> None:
    if vid in store.videos:
        raise ValueError("duplicate video")
    store.videos.add(vid)
    store.parent[vid] = parent
    store.children.setdefault(vid, [])
    store.container_label[vid] = label
    store.available[vid] = set(langs)
    if parent is not None:
        if parent not in store.videos:
            store.videos.add(parent)
            store.parent.setdefault(parent, None)
            store.children.setdefault(parent, [])
            store.available.setdefault(parent, set())
            store.container_label.setdefault(parent, "container")
        store.children[parent].append(vid)

def _shared_parent_lookup(store: VideoStore, vid: str) -> str | None:
    # relation-based, container-label-restricted lookup (not scalar childIds)
    p = store.parent.get(vid)
    if p is None:
        return None
    if store.container_label.get(p) != "container":
        return None
    return p

def recompute_available(store: VideoStore, vid: str) -> set[str]:
    # union of children's languages via BFS closure (hand-rolled)
    if vid not in store.videos:
        return set()
    langs: set[str] = set(store.available.get(vid, set()))
    q: deque[str] = deque(store.children.get(vid, []))
    seen: set[str] = set([vid])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        langs.update(store.available.get(cur, set()))
        for ch in store.children.get(cur, []):
            if ch not in seen:
                q.append(ch)
    return langs

def create_empty_parent_variant(store: VideoStore, parent_id: str) -> str:
    # use shared lookup + recompute engine, not hand-rolled array math
    if parent_id not in store.videos:
        raise KeyError(parent_id)
    # create empty variant id
    variant_id = parent_id + "::variant"
    if variant_id in store.videos:
        return variant_id
    # locate parent via shared lookup: parent must be container
    # if parent_id itself is container, variant is child
    label = store.container_label.get(parent_id, "container")
    if label != "container":
        raise ValueError("not a container parent")
    add_video(store, variant_id, parent_id, "variant", set())
    # recompute via shared engine
    new_langs = recompute_available(store, parent_id)
    store.available[parent_id] = new_langs
    return variant_id

def check_and_remove_empty_parent_variant(store: VideoStore, variant_id: str) -> bool:
    if variant_id not in store.videos:
        return False
    parent = _shared_parent_lookup(store, variant_id)
    if parent is None:
        return False
    # only remove if variant has no languages and is empty
    if store.available.get(variant_id):
        return False
    # remove
    store.videos.remove(variant_id)
    store.available.pop(variant_id, None)
    lab = store.container_label.pop(variant_id, None)
    parent_children = store.children.get(parent, [])
    if variant_id in parent_children:
        parent_children.remove(variant_id)
    store.parent.pop(variant_id, None)
    # recompute parent
    store.available[parent] = recompute_available(store, parent)
    return True

def available_languages(store: VideoStore, vid: str) -> list[str]:
    return sorted(store.available.get(vid, set()))
