"""fbientrigo/dihiggs_hep_cross#17 — versioned generated-event handoff lineage reach."""

from __future__ import annotations

from collections import deque


class _SampleNode:
    __slots__ = ("sid", "point_id", "out")

    def __init__(self, sid: str, point_id: str) -> None:
        self.sid = sid
        self.point_id = point_id
        self.out: list[_SampleNode] = []


def _sorted_out(nd: _SampleNode) -> list[_SampleNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.sid)
    return kids


def _find_sample(sid: str, store: dict) -> _SampleNode | None:
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
        nd = _find_sample(sid, store)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                stack.append(child.sid)
    return order


def fresh_handoff_store() -> dict:
    return {"samples": {}, "deps": {}, "rev": {}, "nodes": {}, "points": {}}


def register_sample(sample_id: str, point_id: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_handoff_store()
    s["samples"][sample_id] = point_id
    s["points"][point_id] = sample_id
    deps = s["deps"]
    if sample_id not in deps:
        deps[sample_id] = []
    rev = s["rev"]
    if sample_id not in rev:
        rev[sample_id] = []
    nd = _SampleNode(sid=sample_id, point_id=point_id)
    s["nodes"][sample_id] = nd
    return s


def add_lineage_edge(source_id: str, target_id: str, store: dict) -> None:
    smap = store["samples"]
    if source_id not in smap or target_id not in smap:
        raise KeyError("unknown sample id")
    if source_id == target_id:
        return
    src_nd = _find_sample(source_id, store)
    tgt_nd = _find_sample(target_id, store)
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


def direct_downstream(sample_id: str, store: dict) -> list[str]:
    if sample_id not in store["samples"]:
        raise KeyError(sample_id)
    return list(store["deps"].get(sample_id, []))


def direct_upstream(sample_id: str, store: dict) -> list[str]:
    if sample_id not in store["samples"]:
        raise KeyError(sample_id)
    return list(store["rev"].get(sample_id, []))


def reachable_samples(start_id: str, store: dict) -> list[str]:
    if start_id not in store["samples"]:
        raise KeyError(start_id)
    start_nd = _find_sample(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for sid in _reach_order(start_id, store):
        if sid != start_id:
            reach.append(sid)
    return reach


def handoff_report(sample_id: str, store: dict) -> dict:
    if sample_id not in store["samples"]:
        raise KeyError(sample_id)
    reach = reachable_samples(sample_id, store)
    return {
        "point_id": store["samples"][sample_id],
        "direct": direct_downstream(sample_id, store),
        "reach": reach,
        "reach_count": len(reach),
    }
