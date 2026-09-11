"""ist-h-i/agent-spectrum-kernel#275 — epic admission and work-package execution topology."""

from __future__ import annotations

from collections import deque

ADMIT_ORDINARY = "ordinary"
ADMIT_EPIC = "epic"
CHECKPOINT_OK = "ok"
CHECKPOINT_ROLLOVER = "rollover"


class _PkgNode:
    __slots__ = ("wp_id", "tokens", "out")

    def __init__(self, wp_id: str, tokens: int) -> None:
        self.wp_id = wp_id
        self.tokens = tokens
        self.out: list[_PkgNode] = []


def _sorted_out(nd: _PkgNode) -> list[_PkgNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.wp_id)
    return kids


def _find_pkg(wp_id: str, store: dict) -> _PkgNode | None:
    nmap = store["nodes"]
    if wp_id in nmap:
        return nmap[wp_id]
    return None


def _reach_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    queue: deque[str] = deque([start_id])
    nodes = store["nodes"]
    while queue:
        pid = queue.popleft()
        if pid in claimed:
            continue
        claimed[pid] = True
        order.append(pid)
        nd = nodes.get(pid)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                queue.appendleft(child.wp_id)
    return order


def fresh_epic_store() -> dict:
    return {"packages": {}, "tokens": {}, "deps": {}, "rev": {}, "nodes": {}, "roots": []}


def register_package(wp_id: str, tokens: int, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_epic_store()
    s["packages"][wp_id] = True
    s["tokens"][wp_id] = tokens
    outs = s["deps"]
    if wp_id not in outs:
        outs[wp_id] = []
    revs = s["rev"]
    if wp_id not in revs:
        revs[wp_id] = []
    nd = _PkgNode(wp_id=wp_id, tokens=tokens)
    s["roots"].append(wp_id)
    s["nodes"][wp_id] = nd
    return s


def add_pkg_dep(source_id: str, target_id: str, store: dict) -> None:
    pmap = store["packages"]
    if source_id not in pmap or target_id not in pmap:
        raise KeyError("unknown package id")
    if source_id == target_id:
        return
    src_nd = _find_pkg(source_id, store)
    tgt_nd = _find_pkg(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.wp_id == target_id for ex in src_nd.out)
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


def direct_deps(wp_id: str, store: dict) -> list[str]:
    if wp_id not in store["packages"]:
        raise KeyError(wp_id)
    return list(store["deps"].get(wp_id, []))


def execution_topology(start_id: str, store: dict) -> list[str]:
    if start_id not in store["packages"]:
        raise KeyError(start_id)
    start_nd = _find_pkg(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for pid in _reach_order(start_id, store):
        if pid != start_id:
            reach.append(pid)
    reach = sorted(reach)
    return reach


def admit_epic(store: dict, token_threshold: int) -> str:
    total = 0
    for pid in store["packages"].keys():
        total += store["tokens"].get(pid, 0)
    if total > token_threshold:
        return ADMIT_EPIC
    return ADMIT_ORDINARY


def checkpoint_status(active_tokens: int, context_threshold: int) -> str:
    if active_tokens >= context_threshold:
        return CHECKPOINT_ROLLOVER
    return CHECKPOINT_OK


def epic_report(
    start_id: str,
    store: dict,
    token_threshold: int,
    context_threshold: int,
    active_tokens: int,
) -> dict:
    if start_id not in store["packages"]:
        raise KeyError(start_id)
    topo = execution_topology(start_id, store)
    direct = direct_deps(start_id, store)
    admission = admit_epic(store, token_threshold)
    checkpoint = checkpoint_status(active_tokens, context_threshold)
    return {
        "admission": admission,
        "checkpoint": checkpoint,
        "direct": direct,
        "topology": topo,
        "topology_count": len(topo),
    }
