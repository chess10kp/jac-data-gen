"""eugenemalaschuk-source/arch-linter-net#516 — deterministic architecture metric semantics."""

from __future__ import annotations

from collections import deque


class _ComponentNode:
    __slots__ = ("cid", "out")

    def __init__(self, cid: str) -> None:
        self.cid = cid
        self.out: list[_ComponentNode] = []


def _sorted_out(nd: _ComponentNode) -> list[_ComponentNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.cid)
    return kids


def _find_component(cid: str, store: dict) -> _ComponentNode | None:
    nmap = store["nodes"]
    if cid in nmap:
        return nmap[cid]
    return None


def _reach_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    stack: deque[str] = deque([start_id])
    while stack:
        cid = stack.pop()
        if cid in claimed:
            continue
        claimed[cid] = True
        order.append(cid)
        nd = _find_component(cid, store)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                stack.append(child.cid)
    return order


def fresh_metric_store() -> dict:
    return {"components": {}, "deps": {}, "rev": {}, "nodes": {}}


def register_component(component_id: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_metric_store()
    s["components"][component_id] = True
    deps = s["deps"]
    if component_id not in deps:
        deps[component_id] = []
    rev = s["rev"]
    if component_id not in rev:
        rev[component_id] = []
    nd = _ComponentNode(cid=component_id)
    s["nodes"][component_id] = nd
    return s


def add_dependency(source_id: str, target_id: str, store: dict) -> None:
    cmap = store["components"]
    if source_id not in cmap or target_id not in cmap:
        raise KeyError("unknown component id")
    if source_id == target_id:
        return
    src_nd = _find_component(source_id, store)
    tgt_nd = _find_component(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.cid == target_id for ex in src_nd.out)
        if not seen:
            src_nd.out.append(tgt_nd)
    outs = store["deps"]
    if source_id not in outs:
        outs[source_id] = []
    if target_id not in outs[source_id]:
        outs[source_id].append(target_id)
        outs[source_id] = sorted(outs[source_id])
    revs = store["rev"]
    if target_id not in revs:
        revs[target_id] = []
    if source_id not in revs[target_id]:
        revs[target_id].append(source_id)
        revs[target_id] = sorted(revs[target_id])


def distinct_outgoing(component_id: str, store: dict) -> list[str]:
    if component_id not in store["components"]:
        raise KeyError(component_id)
    return list(store["deps"].get(component_id, []))


def distinct_incoming(component_id: str, store: dict) -> list[str]:
    if component_id not in store["components"]:
        raise KeyError(component_id)
    return list(store["rev"].get(component_id, []))


def transitive_targets(component_id: str, store: dict) -> list[str]:
    if component_id not in store["components"]:
        raise KeyError(component_id)
    start_nd = _find_component(component_id, store)
    if start_nd is None:
        raise KeyError(component_id)
    reach: list[str] = []
    for cid in _reach_order(component_id, store):
        if cid != component_id:
            reach.append(cid)
    return reach


def metric_report(component_id: str, store: dict) -> dict:
    out = distinct_outgoing(component_id, store)
    inc = distinct_incoming(component_id, store)
    reach = transitive_targets(component_id, store)
    return {
        "out_degree": len(out),
        "in_degree": len(inc),
        "reach_count": len(reach),
        "outgoing": out,
        "incoming": inc,
        "reach": reach,
    }
