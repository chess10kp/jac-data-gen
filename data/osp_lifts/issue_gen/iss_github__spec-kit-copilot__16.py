"""github/spec-kit-copilot#16 — inter-feature dependency stack reachability."""
from __future__ import annotations

from collections import deque


class _Node:
    __slots__ = ("fid", "out")

    def __init__(self, fid: str) -> None:
        self.fid = fid
        self.out: list[_Node] = []


def _sorted_out(nd: _Node) -> list[_Node]:
    return sorted(nd.out, key=lambda n: n.fid)


def _reach_order(start_id: str, store: dict) -> list[str]:
    start = store["nodes"][start_id]
    claimed: dict[str, bool] = {}
    order: list[str] = []
    stack: deque[_Node] = deque([start])
    while stack:
        nd = stack.pop()
        if nd.fid in claimed:
            continue
        claimed[nd.fid] = True
        order.append(nd.fid)
        for ch in reversed(_sorted_out(nd)):
            stack.append(ch)
    return order


def _find_feature(fid: str, store: dict) -> _Node | None:
    nmap = store["nodes"]
    if fid in nmap:
        return nmap[fid]
    return None


def fresh_stack_store() -> dict:
    return {"features": {}, "deps": {}, "rev": {}, "nodes": {}, "stacked": {}, "lanes": {}}


def register_feature(feature_id: str, store: dict | None = None) -> dict:
    s = store if store is not None else fresh_stack_store()
    s["features"][feature_id] = True
    outs = s["deps"]
    if feature_id not in outs:
        outs[feature_id] = []
    rev = s["rev"]
    if feature_id not in rev:
        rev[feature_id] = []
    s["stacked"][feature_id] = False
    s["lanes"][feature_id] = 0
    s["nodes"][feature_id] = _Node(feature_id)
    return s


def add_dependency_edge(upstream_id: str, dependent_id: str, store: dict) -> None:
    fmap = store["features"]
    if upstream_id not in fmap or dependent_id not in fmap:
        raise KeyError("unknown feature id")
    if upstream_id == dependent_id:
        return
    up_nd = _find_feature(upstream_id, store)
    dep_nd = _find_feature(dependent_id, store)
    if up_nd is not None and dep_nd is not None:
        if not any(ex.fid == dependent_id for ex in up_nd.out):
            up_nd.out.append(dep_nd)
    outs = store["deps"]
    if upstream_id not in outs:
        outs[upstream_id] = []
    if dependent_id not in outs[upstream_id]:
        outs[upstream_id].append(dependent_id)
        outs[upstream_id] = sorted(outs[upstream_id])
    revs = store["rev"]
    if dependent_id not in revs:
        revs[dependent_id] = []
    if upstream_id not in revs[dependent_id]:
        revs[dependent_id].append(upstream_id)
        revs[dependent_id] = sorted(revs[dependent_id])


def direct_dependents(upstream_id: str, store: dict) -> list[str]:
    if upstream_id not in store["features"]:
        raise KeyError(upstream_id)
    return list(store["deps"].get(upstream_id, []))


def reachable_dependents(start_id: str, store: dict) -> list[str]:
    if start_id not in store["features"]:
        raise KeyError(start_id)
    if _find_feature(start_id, store) is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for fid in _reach_order(start_id, store):
        if fid != start_id:
            reach.append(fid)
    return reach


def cascade_mark_stacked(start_id: str, store: dict) -> list[str]:
    if start_id not in store["features"]:
        raise KeyError(start_id)
    reach = reachable_dependents(start_id, store)
    stacked = store["stacked"]
    lanes = store["lanes"]
    marked: list[str] = [start_id]
    stacked[start_id] = True
    lanes[start_id] = 1
    layer = 2
    for fid in reach:
        stacked[fid] = True
        lanes[fid] = layer
        layer += 1
        marked.append(fid)
    return sorted(marked)


def stack_report(feature_id: str, store: dict) -> dict:
    if feature_id not in store["features"]:
        raise KeyError(feature_id)
    reach = reachable_dependents(feature_id, store)
    direct = direct_dependents(feature_id, store)
    stacked = store["stacked"]
    stack_count = 0
    for fid in reach:
        if stacked.get(fid, False):
            stack_count += 1
    if stacked.get(feature_id, False):
        stack_count += 1
    return {
        "direct": direct,
        "reach": reach,
        "reach_count": len(reach),
        "stacked": stacked.get(feature_id, False),
        "stack_layer_count": stack_count,
    }
