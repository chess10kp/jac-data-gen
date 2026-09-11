"""payloadcms/payload#17658 — subtree walk excludes descendants for parent picker."""
from __future__ import annotations

from collections import deque


class Doc:
    def __init__(self, id: str, title: str) -> None:
        self.id = id
        self.title = title
        self._child_ids: list[str] = []


def make_doc(doc_id: str, title: str) -> Doc:
    return Doc(id=doc_id, title=title)


def register_doc(store: dict[str, Doc], nd: Doc) -> Doc:
    store[nd.id] = nd
    return nd


def connect_parent(parent: Doc, child: Doc) -> None:
    parent._child_ids.append(child.id)


def _children_of(here: Doc, store: dict[str, Doc]) -> list[Doc]:
    kids: list[Doc] = []
    for cid in here._child_ids:
        if cid in store:
            kids.append(store[cid])
    return kids


def broken_breadcrumb_not_in_match(editing_id: str, breadcrumb_docs: list[str]) -> bool:
    for row_doc in breadcrumb_docs:
        if row_doc != editing_id:
            return True
    return False


def collect_descendant_ids(editing_id: str, store: dict[str, Doc]) -> list[str]:
    if editing_id not in store:
        empty: list[str] = []
        return empty
    origin_id = editing_id
    claimed: dict[str, bool] = {}
    found: list[str] = []
    queue: deque[Doc] = deque([store[editing_id]])
    while queue:
        here = queue.popleft()
        if here.id in claimed:
            continue
        claimed[here.id] = True
        if here.id != origin_id:
            found.append(here.id)
        kids = _children_of(here, store)
        for kid in kids:
            queue.appendleft(kid)
    return sorted(found)


def build_excluded_ids(editing_id: str, store: dict[str, Doc]) -> list[str]:
    excluded: list[str] = [editing_id]
    desc = collect_descendant_ids(editing_id, store)
    for d in desc:
        excluded.append(d)
    return sorted(excluded)


def filter_parent_candidates(
    editing_id: str, candidates: list[str], store: dict[str, Doc]
) -> list[str]:
    ex = build_excluded_ids(editing_id, store)
    blocked: dict[str, bool] = {}
    for e in ex:
        blocked[e] = True
    kept: list[str] = []
    for cid in candidates:
        if cid in blocked:
            continue
        kept.append(cid)
    return sorted(kept)


def would_create_cycle(editing_id: str, new_parent_id: str, store: dict[str, Doc]) -> bool:
    blocked = build_excluded_ids(editing_id, store)
    for e in blocked:
        if e == new_parent_id:
            return True
    return False
