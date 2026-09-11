"""tstapler/stapler-squad#460 — backlog dependency ordering blocks premature dequeue."""

from __future__ import annotations

from collections import deque


class BacklogStore:
    def __init__(self) -> None:
        self._items: set[str] = set()
        self._status: dict[str, str] = {}
        self._blocked_by: dict[str, list[str]] = {}


def load_backlog(
    items: list[str],
    blocked_by: list[tuple[str, str]],
    status: list[tuple[str, str]] | None = None,
) -> BacklogStore:
    b = BacklogStore()
    for iid in items:
        b._items.add(iid)
        b._status[iid] = "idea"
        b._blocked_by.setdefault(iid, [])
    for item, blocker in blocked_by:
        if item in b._items and blocker in b._items:
            b._blocked_by.setdefault(item, []).append(blocker)
    for iid, st in status or []:
        if iid in b._items:
            b._status[iid] = st
    return b


def _unresolved_blockers(b: BacklogStore, item: str) -> list[str]:
    blockers = []
    for blk in b._blocked_by.get(item, []):
        if b._status.get(blk) != "shipped":
            blockers.append(blk)
    return sorted(blockers)


def is_dequeue_allowed(b: BacklogStore, item: str) -> bool:
    if item not in b._items:
        return False
    return len(_unresolved_blockers(b, item)) == 0


def blocked_by_unshipped(b: BacklogStore, item: str) -> list[str]:
    if item not in b._items:
        return []
    return _unresolved_blockers(b, item)


def transitive_blockers(b: BacklogStore, item: str) -> list[str]:
    if item not in b._items:
        return []
    seen: set[str] = set()
    q: deque[str] = deque(_unresolved_blockers(b, item))
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        for nxt in _unresolved_blockers(b, cur):
            if nxt not in seen:
                q.append(nxt)
    return sorted(hits)
