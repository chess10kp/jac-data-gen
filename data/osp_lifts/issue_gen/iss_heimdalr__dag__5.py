"""heimdalr/dag#5 — DAG edge add with ancestor cache invalidation on descendants."""

from __future__ import annotations

from collections import deque


class _VertexNode:
    __slots__ = ("vid", "out")

    def __init__(self, vid: str) -> None:
        self.vid = vid
        self.out: list[_VertexNode] = []


def _sorted_out(nd: _VertexNode) -> list[_VertexNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.vid)
    return kids


def _sorted_in(vid: str, store: dict) -> list[_VertexNode]:
    nodes = store["nodes"]
    ordered: list[_VertexNode] = []
    for nm in sorted(store["rev"].get(vid, [])):
        nd = nodes.get(nm)
        if nd is not None:
            ordered.append(nd)
    return ordered


def _find_vertex(vid: str, store: dict) -> _VertexNode | None:
    nmap = store["nodes"]
    if vid in nmap:
        return nmap[vid]
    return None


def _reach_down(start_id: str, store: dict) -> list[str]:
    start_nd = _find_vertex(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    claimed: dict[str, bool] = {}
    order: list[str] = []
    queue: deque[str] = deque([start_id])
    nodes = store["nodes"]
    while queue:
        vid = queue.popleft()
        if vid in claimed:
            continue
        claimed[vid] = True
        order.append(vid)
        nd = nodes.get(vid)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                queue.appendleft(child.vid)
    reach: list[str] = []
    for vid in order:
        if vid != start_id:
            reach.append(vid)
    return reach


def _reach_up(start_id: str, store: dict) -> list[str]:
    start_nd = _find_vertex(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    claimed: dict[str, bool] = {}
    order: list[str] = []
    queue: deque[str] = deque([start_id])
    while queue:
        vid = queue.popleft()
        if vid in claimed:
            continue
        claimed[vid] = True
        order.append(vid)
        for parent in reversed(_sorted_in(vid, store)):
            queue.appendleft(parent.vid)
    reach: list[str] = []
    for vid in order:
        if vid != start_id:
            reach.append(vid)
    return reach


def fresh_dag_store() -> dict:
    return {
        "vertices": {},
        "deps": {},
        "rev": {},
        "nodes": {},
        "ancestors_cache": {},
        "descendants_cache": {},
    }


def register_vertex(vid: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_dag_store()
    s["vertices"][vid] = True
    outs = s["deps"]
    if vid not in outs:
        outs[vid] = []
    revs = s["rev"]
    if vid not in revs:
        revs[vid] = []
    nd = _VertexNode(vid=vid)
    s["nodes"][vid] = nd
    return s


def _has_edge(source_id: str, target_id: str, store: dict) -> bool:
    outs = store["deps"]
    return target_id in outs.get(source_id, [])


def _invalidate_ancestor_cache(vids: list[str], store: dict) -> int:
    cache = store["ancestors_cache"]
    n = 0
    for vid in vids:
        if vid in cache:
            del cache[vid]
            n += 1
    return n


def add_dag_edge(source_id: str, target_id: str, store: dict) -> None:
    vmap = store["vertices"]
    if source_id not in vmap or target_id not in vmap:
        raise KeyError("unknown vertex id")
    if _has_edge(source_id, target_id, store):
        raise ValueError("duplicate edge")
    descendants = _reach_down(target_id, store)
    if source_id == target_id or source_id in descendants:
        raise ValueError("edge loop")
    src_nd = _find_vertex(source_id, store)
    tgt_nd = _find_vertex(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.vid == target_id for ex in src_nd.out)
        if not seen:
            src_nd.out.append(tgt_nd)
    outs = store["deps"]
    if target_id not in outs[source_id]:
        outs[source_id].append(target_id)
        outs[source_id] = sorted(outs[source_id])
    revs = store["rev"]
    if source_id not in revs[target_id]:
        revs[target_id].append(source_id)
        revs[target_id] = sorted(revs[target_id])
    inv: list[str] = [target_id]
    for vid in descendants:
        inv.append(vid)
    _invalidate_ancestor_cache(inv, store)
    dcache = store["descendants_cache"]
    for key in list(dcache.keys()):
        del dcache[key]


def get_descendants(vid: str, store: dict) -> list[str]:
    if vid not in store["vertices"]:
        raise KeyError(vid)
    dcache = store["descendants_cache"]
    if vid in dcache:
        return list(dcache[vid])
    reach = sorted(_reach_down(vid, store))
    dcache[vid] = reach
    return list(reach)


def get_ancestors(vid: str, store: dict) -> list[str]:
    if vid not in store["vertices"]:
        raise KeyError(vid)
    acache = store["ancestors_cache"]
    if vid in acache:
        return list(acache[vid])
    reach = sorted(_reach_up(vid, store))
    acache[vid] = reach
    return list(reach)


def edge_add_report(source_id: str, target_id: str, store: dict) -> dict:
    descendants = get_descendants(target_id, store)
    ancestors = get_ancestors(source_id, store)
    return {
        "descendant_count": len(descendants),
        "ancestor_count": len(ancestors),
        "cache_keys": len(store["ancestors_cache"]),
    }
