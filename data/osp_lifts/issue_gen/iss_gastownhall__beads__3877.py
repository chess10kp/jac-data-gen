"""gastownhall/beads#3877 — recursive blocks closure for ready-work reach."""

from __future__ import annotations

from collections import deque


class _IssueNode:
    __slots__ = ("iid", "out")

    def __init__(self, iid: str) -> None:
        self.iid = iid
        self.out: list[_IssueNode] = []


def _sorted_out(nd: _IssueNode) -> list[_IssueNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.iid)
    return kids


def _find_issue(iid: str, store: dict) -> _IssueNode | None:
    nmap = store["nodes"]
    if iid in nmap:
        return nmap[iid]
    return None


def _reach_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    stack: deque[str] = deque([start_id])
    while stack:
        iid = stack.pop()
        if iid in claimed:
            continue
        claimed[iid] = True
        order.append(iid)
        nd = _find_issue(iid, store)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                stack.append(child.iid)
    return order


def fresh_issue_store() -> dict:
    return {"issues": {}, "blocks": {}, "rev": {}, "nodes": {}}


def register_issue(issue_id: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_issue_store()
    s["issues"][issue_id] = True
    outs = s["blocks"]
    if issue_id not in outs:
        outs[issue_id] = []
    rev = s["rev"]
    if issue_id not in rev:
        rev[issue_id] = []
    nd = _IssueNode(iid=issue_id)
    s["nodes"][issue_id] = nd
    return s


def add_blocks_edge(blocker_id: str, blocked_id: str, store: dict) -> None:
    imap = store["issues"]
    if blocker_id not in imap or blocked_id not in imap:
        raise KeyError("unknown issue id")
    if blocker_id == blocked_id:
        return
    src_nd = _find_issue(blocker_id, store)
    tgt_nd = _find_issue(blocked_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.iid == blocked_id for ex in src_nd.out)
        if not seen:
            src_nd.out.append(tgt_nd)
    outs = store["blocks"]
    if blocker_id not in outs:
        outs[blocker_id] = []
    if blocked_id not in outs[blocker_id]:
        outs[blocker_id].append(blocked_id)
        outs[blocker_id] = sorted(outs[blocker_id])
    revs = store["rev"]
    if blocked_id not in revs:
        revs[blocked_id] = []
    if blocker_id not in revs[blocked_id]:
        revs[blocked_id].append(blocker_id)
        revs[blocked_id] = sorted(revs[blocked_id])


def direct_blocked(blocker_id: str, store: dict) -> list[str]:
    if blocker_id not in store["issues"]:
        raise KeyError(blocker_id)
    return list(store["blocks"].get(blocker_id, []))


def direct_blockers(blocked_id: str, store: dict) -> list[str]:
    if blocked_id not in store["issues"]:
        raise KeyError(blocked_id)
    return list(store["rev"].get(blocked_id, []))


def transitive_blocked(start_id: str, store: dict) -> list[str]:
    if start_id not in store["issues"]:
        raise KeyError(start_id)
    start_nd = _find_issue(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for iid in _reach_order(start_id, store):
        if iid != start_id:
            reach.append(iid)
    return reach


def ready_reach_report(start_id: str, store: dict) -> dict:
    reach = transitive_blocked(start_id, store)
    direct = direct_blocked(start_id, store)
    return {"direct": direct, "reach": reach, "reach_count": len(reach)}
