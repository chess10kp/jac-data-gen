"""huyhandes/groxpi#44 — groxpi module dependency flow reachability mapping."""

from __future__ import annotations

from collections import deque

KIND_REQUEST = "request"
KIND_SYNC = "sync"


class _ModuleNode:
    __slots__ = ("mid", "kind", "out")

    def __init__(self, mid: str, kind: str) -> None:
        self.mid = mid
        self.kind = kind
        self.out: list[_ModuleNode] = []


def _sorted_out(nd: _ModuleNode) -> list[_ModuleNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.mid)
    return kids


def _find_module(mid: str, store: dict) -> _ModuleNode | None:
    nmap = store["nodes"]
    if mid in nmap:
        return nmap[mid]
    return None


def _reach_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    queue: deque[str] = deque([start_id])
    nodes = store["nodes"]
    while queue:
        mid = queue.popleft()
        if mid in claimed:
            continue
        claimed[mid] = True
        order.append(mid)
        nd = nodes.get(mid)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                queue.appendleft(child.mid)
    return order


def fresh_module_store() -> dict:
    return {"modules": {}, "kinds": {}, "deps": {}, "rev": {}, "nodes": {}, "roots": []}


def register_module(mid: str, kind: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_module_store()
    s["modules"][mid] = True
    s["kinds"][mid] = kind
    outs = s["deps"]
    if mid not in outs:
        outs[mid] = []
    revs = s["rev"]
    if mid not in revs:
        revs[mid] = []
    nd = _ModuleNode(mid=mid, kind=kind)
    s["roots"].append(mid)
    s["nodes"][mid] = nd
    return s


def add_module_dep(source_id: str, target_id: str, store: dict) -> None:
    mmap = store["modules"]
    if source_id not in mmap or target_id not in mmap:
        raise KeyError("unknown module id")
    if source_id == target_id:
        return
    src_nd = _find_module(source_id, store)
    tgt_nd = _find_module(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.mid == target_id for ex in src_nd.out)
        if not seen:
            src_nd.out.append(tgt_nd)
        roots = store["roots"]
        if target_id in roots:
            roots.remove(target_id)
    outs = store["deps"]
    if target_id not in outs[source_id]:
        outs[source_id].append(target_id)
        outs[source_id] = sorted(outs[source_id])
    revs = store["rev"]
    if source_id not in revs[target_id]:
        revs[target_id].append(source_id)
        revs[target_id] = sorted(revs[target_id])


def direct_deps(module_id: str, store: dict) -> list[str]:
    if module_id not in store["modules"]:
        raise KeyError(module_id)
    return list(store["deps"].get(module_id, []))


def reachable_modules(start_id: str, store: dict) -> list[str]:
    if start_id not in store["modules"]:
        raise KeyError(start_id)
    start_nd = _find_module(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for mid in _reach_order(start_id, store):
        if mid != start_id:
            reach.append(mid)
    reach = sorted(reach)
    return reach


def pipeline_report(start_id: str, store: dict) -> dict:
    if start_id not in store["modules"]:
        raise KeyError(start_id)
    reach = reachable_modules(start_id, store)
    direct = direct_deps(start_id, store)
    kinds = store["kinds"]
    req_count = 0
    sync_count = 0
    for mid in reach:
        k = kinds.get(mid, "")
        if k == KIND_REQUEST:
            req_count += 1
        if k == KIND_SYNC:
            sync_count += 1
    return {
        "direct": direct,
        "reach": reach,
        "reach_count": len(reach),
        "request_modules": req_count,
        "sync_modules": sync_count,
    }
