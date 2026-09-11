"""gastownhall/beads#5397 — N+1 engine opens scale descendant list cost by node count."""

from __future__ import annotations

from collections import deque

ENGINE_OPEN_MS = 1800
PER_NODE_MS = 250
LIGHT_PER_NODE_MS = 110


class _TreeNode:
    __slots__ = ("nid", "out")

    def __init__(self, nid: str) -> None:
        self.nid = nid
        self.out: list[_TreeNode] = []


def _sorted_children(nd: _TreeNode) -> list[_TreeNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.nid)
    return kids


def _find_node(nid: str, store: dict) -> _TreeNode | None:
    nmap = store["nodes"]
    if nid in nmap:
        return nmap[nid]
    return None


def _reach_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    stack: deque[str] = deque([start_id])
    while stack:
        nid = stack.pop()
        if nid in claimed:
            continue
        claimed[nid] = True
        order.append(nid)
        nd = _find_node(nid, store)
        if nd is not None:
            for child in reversed(_sorted_children(nd)):
                stack.append(child.nid)
    return order


def fresh_tree_store() -> dict:
    return {"nodes_map": {}, "children": {}, "rev": {}, "nodes": {}}


def register_node(node_id: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_tree_store()
    s["nodes_map"][node_id] = True
    kids = s["children"]
    if node_id not in kids:
        kids[node_id] = []
    rev = s["rev"]
    if node_id not in rev:
        rev[node_id] = []
    nd = _TreeNode(nid=node_id)
    s["nodes"][node_id] = nd
    return s


def add_parent_edge(parent_id: str, child_id: str, store: dict) -> None:
    nmap = store["nodes_map"]
    if parent_id not in nmap or child_id not in nmap:
        raise KeyError("unknown node id")
    if parent_id == child_id:
        return
    par_nd = _find_node(parent_id, store)
    ch_nd = _find_node(child_id, store)
    if par_nd is not None and ch_nd is not None:
        seen = any(ex.nid == child_id for ex in par_nd.out)
        if not seen:
            par_nd.out.append(ch_nd)
    outs = store["children"]
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


def direct_children(parent_id: str, store: dict) -> list[str]:
    if parent_id not in store["nodes_map"]:
        raise KeyError(parent_id)
    return list(store["children"].get(parent_id, []))


def reachable_descendants(start_id: str, store: dict) -> list[str]:
    if start_id not in store["nodes_map"]:
        raise KeyError(start_id)
    start_nd = _find_node(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for nid in _reach_order(start_id, store):
        if nid != start_id:
            reach.append(nid)
    return reach


def list_cost_ms(start_id: str, store: dict, journal_heavy: bool = False) -> int:
    if start_id not in store["nodes_map"]:
        raise KeyError(start_id)
    reach = reachable_descendants(start_id, store)
    per = PER_NODE_MS if journal_heavy else LIGHT_PER_NODE_MS
    return ENGINE_OPEN_MS + (len(reach) + 1) * per


def descendant_report(start_id: str, store: dict, journal_heavy: bool = False) -> dict:
    reach = reachable_descendants(start_id, store)
    direct = direct_children(start_id, store)
    return {
        "direct": direct,
        "reach": reach,
        "reach_count": len(reach),
        "nodes_walked": len(reach) + 1,
        "cost_ms": list_cost_ms(start_id, store, journal_heavy),
        "journal_heavy": journal_heavy,
    }
