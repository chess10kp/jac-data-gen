"""fleetdm/fleet#42933 — workflow cache invalidation reach for clean CVE rebuild."""

from __future__ import annotations

from collections import deque

RUN_MODE_CLEAN = "clean"
RUN_MODE_INCREMENTAL = "incremental"


class _StageNode:
    __slots__ = ("sid", "out")

    def __init__(self, sid: str) -> None:
        self.sid = sid
        self.out: list[_StageNode] = []


def _sorted_out(nd: _StageNode) -> list[_StageNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.sid)
    return kids


def _find_stage(sid: str, store: dict) -> _StageNode | None:
    nmap = store["nodes"]
    if sid in nmap:
        return nmap[sid]
    return None


def _reach_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    stack: deque[str] = deque([start_id])
    while stack:
        sid = stack.pop()
        if sid in claimed:
            continue
        claimed[sid] = True
        order.append(sid)
        nd = _find_stage(sid, store)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                stack.append(child.sid)
    return order


def fresh_workflow_store() -> dict:
    return {"stages": {}, "deps": {}, "rev": {}, "nodes": {}, "dirty": {}}


def register_stage(stage_id: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_workflow_store()
    s["stages"][stage_id] = True
    deps = s["deps"]
    if stage_id not in deps:
        deps[stage_id] = []
    rev = s["rev"]
    if stage_id not in rev:
        rev[stage_id] = []
    dirty = s["dirty"]
    dirty[stage_id] = False
    nd = _StageNode(sid=stage_id)
    s["nodes"][stage_id] = nd
    return s


def add_stage_edge(source_id: str, target_id: str, store: dict) -> None:
    smap = store["stages"]
    if source_id not in smap or target_id not in smap:
        raise KeyError("unknown stage id")
    if source_id == target_id:
        return
    src_nd = _find_stage(source_id, store)
    tgt_nd = _find_stage(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.sid == target_id for ex in src_nd.out)
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


def direct_downstream(stage_id: str, store: dict) -> list[str]:
    if stage_id not in store["stages"]:
        raise KeyError(stage_id)
    return list(store["deps"].get(stage_id, []))


def reachable_stages(start_id: str, store: dict) -> list[str]:
    if start_id not in store["stages"]:
        raise KeyError(start_id)
    start_nd = _find_stage(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for sid in _reach_order(start_id, store):
        if sid != start_id:
            reach.append(sid)
    return reach


def invalidate_downstream(stage_id: str, store: dict) -> list[str]:
    if stage_id not in store["stages"]:
        raise KeyError(stage_id)
    reach = reachable_stages(stage_id, store)
    dirty = store["dirty"]
    dirty[stage_id] = True
    for sid in reach:
        dirty[sid] = True
    marked: list[str] = [stage_id]
    for sid in reach:
        marked.append(sid)
    marked = sorted(marked)
    return marked


def rebuild_report(stage_id: str, store: dict, force_clean: bool = False) -> dict:
    if stage_id not in store["stages"]:
        raise KeyError(stage_id)
    reach = reachable_stages(stage_id, store)
    direct = direct_downstream(stage_id, store)
    dirty = store["dirty"]
    needs_clean = force_clean or dirty.get(stage_id, False)
    mode = RUN_MODE_CLEAN if needs_clean else RUN_MODE_INCREMENTAL
    return {
        "direct": direct,
        "reach": reach,
        "reach_count": len(reach),
        "run_mode": mode,
        "force_clean": force_clean,
    }
