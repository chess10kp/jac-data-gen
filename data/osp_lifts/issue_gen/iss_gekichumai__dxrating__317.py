"""gekichumai/dxrating#317 — moderation cascade over immutable comment thread reach."""
from __future__ import annotations

from collections import deque


class _Node:
    __slots__ = ("cid", "out")

    def __init__(self, cid: str) -> None:
        self.cid = cid
        self.out: list[_Node] = []


def _sorted_out(nd: _Node) -> list[_Node]:
    return sorted(nd.out, key=lambda n: n.cid)


def _reach_order(start_id: str, store: dict) -> list[str]:
    start = store["nodes"][start_id]
    claimed: dict[str, bool] = {}
    order: list[str] = []
    stack: deque[_Node] = deque([start])
    while stack:
        nd = stack.pop()
        if nd.cid in claimed:
            continue
        claimed[nd.cid] = True
        order.append(nd.cid)
        for ch in reversed(_sorted_out(nd)):
            stack.append(ch)
    return order


def _find_comment(cid: str, store: dict) -> _Node | None:
    nmap = store["nodes"]
    if cid in nmap:
        return nmap[cid]
    return None


def fresh_moderation_store() -> dict:
    return {"comments": {}, "replies": {}, "rev": {}, "nodes": {}, "deleted": {}, "events": {}}


def register_comment(comment_id: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_moderation_store()
    s["comments"][comment_id] = True
    outs = s["replies"]
    if comment_id not in outs:
        outs[comment_id] = []
    rev = s["rev"]
    if comment_id not in rev:
        rev[comment_id] = []
    s["deleted"][comment_id] = False
    events = s["events"]
    if comment_id not in events:
        events[comment_id] = []
    s["nodes"][comment_id] = _Node(comment_id)
    return s


def add_reply_edge(parent_id: str, child_id: str, store: dict) -> None:
    cmap = store["comments"]
    if parent_id not in cmap or child_id not in cmap:
        raise KeyError("unknown comment id")
    if parent_id == child_id:
        return
    par_nd = _find_comment(parent_id, store)
    ch_nd = _find_comment(child_id, store)
    if par_nd is not None and ch_nd is not None:
        seen = any(ex.cid == child_id for ex in par_nd.out)
        if not seen:
            par_nd.out.append(ch_nd)
    outs = store["replies"]
    if parent_id not in outs:
        outs[parent_id] = []
    if child_id not in outs[parent_id]:
        outs[parent_id].append(child_id)
        outs[parent_id] = sorted(outs[parent_id])
    revs = store["rev"]
    if child_id not in revs:
        revs[child_id] = []
    if parent_id not in revs[child_id]:
        revs[child_id].append(parent_id)
        revs[child_id] = sorted(revs[child_id])


def direct_replies(parent_id: str, store: dict) -> list[str]:
    if parent_id not in store["comments"]:
        raise KeyError(parent_id)
    return list(store["replies"].get(parent_id, []))


def reachable_replies(start_id: str, store: dict) -> list[str]:
    if start_id not in store["comments"]:
        raise KeyError(start_id)
    start_nd = _find_comment(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for cid in _reach_order(start_id, store):
        if cid != start_id:
            reach.append(cid)
    return reach


def cascade_mark_deleted(start_id: str, store: dict) -> list[str]:
    if start_id not in store["comments"]:
        raise KeyError(start_id)
    reach = reachable_replies(start_id, store)
    deleted = store["deleted"]
    events = store["events"]
    marked: list[str] = [start_id]
    deleted[start_id] = True
    events[start_id].append("delete")
    for cid in reach:
        deleted[cid] = True
        events[cid].append("delete")
        marked.append(cid)
    return sorted(marked)


def moderation_report(comment_id: str, store: dict) -> dict:
    if comment_id not in store["comments"]:
        raise KeyError(comment_id)
    reach = reachable_replies(comment_id, store)
    direct = direct_replies(comment_id, store)
    deleted = store["deleted"]
    thread_deleted = 0
    for cid in reach:
        if deleted.get(cid, False):
            thread_deleted += 1
    if deleted.get(comment_id, False):
        thread_deleted += 1
    return {
        "direct": direct,
        "reach": reach,
        "reach_count": len(reach),
        "deleted": deleted.get(comment_id, False),
        "thread_deleted_count": thread_deleted,
    }
