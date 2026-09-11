"""grantaj/thorn#112 — dependency-aware review freshness and invalidation cone."""

from __future__ import annotations

from collections import deque

STATE_NEVER = "never_reviewed"
STATE_CURRENT = "current"
STATE_REUSED = "reused"
STATE_LOCAL = "locally_changed"
STATE_UPSTREAM = "upstream_invalidated"


class _ProofNode:
    __slots__ = ("uid", "out")

    def __init__(self, uid: str) -> None:
        self.uid = uid
        self.out: list[_ProofNode] = []


def _sorted_out(nd: _ProofNode) -> list[_ProofNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.uid)
    return kids


def _find_unit(uid: str, store: dict) -> _ProofNode | None:
    nmap = store["nodes"]
    if uid in nmap:
        return nmap[uid]
    return None


def _reach_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    queue: deque[str] = deque([start_id])
    while queue:
        uid = queue.popleft()
        if uid in claimed:
            continue
        claimed[uid] = True
        order.append(uid)
        nd = _find_unit(uid, store)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                queue.appendleft(child.uid)
    return order


def fresh_proof_store() -> dict:
    return {"units": {}, "deps": {}, "rev": {}, "nodes": {}, "records": {}, "cones": {}}


def register_proof_unit(unit_id: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_proof_store()
    s["units"][unit_id] = True
    deps = s["deps"]
    if unit_id not in deps:
        deps[unit_id] = []
    rev = s["rev"]
    if unit_id not in rev:
        rev[unit_id] = []
    recs = s["records"]
    if unit_id not in recs:
        recs[unit_id] = {"state": STATE_NEVER, "reason": ""}
    nd = _ProofNode(uid=unit_id)
    s["nodes"][unit_id] = nd
    return s


def add_proof_dep(source_id: str, target_id: str, store: dict) -> None:
    umap = store["units"]
    if source_id not in umap or target_id not in umap:
        raise KeyError("unknown proof unit id")
    if source_id == target_id:
        return
    src_nd = _find_unit(source_id, store)
    tgt_nd = _find_unit(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.uid == target_id for ex in src_nd.out)
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


def direct_downstream(unit_id: str, store: dict) -> list[str]:
    if unit_id not in store["units"]:
        raise KeyError(unit_id)
    return list(store["deps"].get(unit_id, []))


def reachable_units(start_id: str, store: dict) -> list[str]:
    if start_id not in store["units"]:
        raise KeyError(start_id)
    start_nd = _find_unit(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for uid in _reach_order(start_id, store):
        if uid != start_id:
            reach.append(uid)
    return reach


def attach_review_record(unit_id: str, state: str, reason: str, store: dict) -> None:
    if unit_id not in store["units"]:
        raise KeyError(unit_id)
    recs = store["records"]
    recs[unit_id] = {"state": state, "reason": reason}


def record_invalidation_cone(origin_id: str, affected_ids: list[str], store: dict) -> None:
    if origin_id not in store["units"]:
        raise KeyError(origin_id)
    umap = store["units"]
    for aid in affected_ids:
        if aid not in umap:
            raise KeyError(aid)
    cones = store["cones"]
    cones[origin_id] = sorted(affected_ids)


def invalidation_cone(origin_id: str, store: dict) -> list[str]:
    if origin_id not in store["units"]:
        raise KeyError(origin_id)
    return list(store["cones"].get(origin_id, []))


def freshness_report(unit_id: str, store: dict) -> dict:
    if unit_id not in store["units"]:
        raise KeyError(unit_id)
    rec = store["records"].get(unit_id, {"state": STATE_NEVER, "reason": ""})
    reach = reachable_units(unit_id, store)
    direct = direct_downstream(unit_id, store)
    cone = invalidation_cone(unit_id, store)
    return {
        "state": rec["state"],
        "reason": rec["reason"],
        "direct": direct,
        "reach": reach,
        "cone": cone,
        "reach_count": len(reach),
    }
