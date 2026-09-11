"""autumn-foundation/autumn#2285 — Hard delete_comment cascade through reply tree."""

from __future__ import annotations

from collections import deque


class CommentStore:
    def __init__(self) -> None:
        self._comments: set[str] = set()
        self._record: dict[str, str] = {}
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._counts: dict[str, int] = {}


def load_comments(
    records: list[str],
    comments: list[tuple[str, str]],
    replies: list[tuple[str, str]],
    counts: list[tuple[str, int]],
) -> CommentStore:
    store = CommentStore()
    for rid in records:
        store._counts[rid] = 0
    for cid, rid in comments:
        store._comments.add(cid)
        store._record[cid] = rid
        store._parent[cid] = None
        store._children.setdefault(cid, [])
        store._counts.setdefault(rid, 0)
    for child, parent in replies:
        if child in store._comments and parent in store._comments:
            store._parent[child] = parent
            store._children.setdefault(parent, []).append(child)
    for rid, count in counts:
        store._counts[rid] = count
    return store


def _same_record_subtree(store: CommentStore, root: str) -> list[str]:
    if root not in store._comments:
        return []
    record = store._record[root]
    q: deque[str] = deque([root])
    claimed: set[str] = set()
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for ch in sorted(store._children.get(cur, [])):
            if store._record.get(ch) == record and ch not in claimed:
                q.append(ch)
    return hits


def delete_comment(store: CommentStore, record_id: str, comment_id: str) -> list[str]:
    if comment_id not in store._comments:
        return []
    if store._record[comment_id] != record_id:
        return []
    targets = _same_record_subtree(store, comment_id)
    removed: list[str] = []
    for cid in targets:
        if cid in store._comments:
            store._comments.discard(cid)
            removed.append(cid)
    if record_id in store._counts:
        store._counts[record_id] = max(0, store._counts[record_id] - len(removed))
    return sorted(removed)


def comment_count(store: CommentStore, record_id: str) -> int:
    return store._counts.get(record_id, 0)


def remaining_comments(store: CommentStore, record_id: str) -> list[str]:
    return sorted(
        cid for cid in store._comments if store._record.get(cid) == record_id
    )


def cross_record_orphans(store: CommentStore, record_id: str) -> list[str]:
    # Comments on record_id whose parent lives on another record.
    bad: list[str] = []
    for cid in sorted(store._comments):
        if store._record.get(cid) != record_id:
            continue
        parent = store._parent.get(cid)
        if parent is not None and store._record.get(parent) != record_id:
            bad.append(cid)
    return bad
