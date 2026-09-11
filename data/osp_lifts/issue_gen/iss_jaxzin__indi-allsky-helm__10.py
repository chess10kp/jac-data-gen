"""jaxzin/indi-allsky-helm#10 — chart release workflow DAG and GitOps reach topology."""

from __future__ import annotations

from collections import deque

KIND_WORKFLOW = "workflow"
KIND_DOCS = "docs"
KIND_EXAMPLE = "example"
KIND_GATE = "gate"
STATUS_BLOCKED = "blocked"
STATUS_READY = "ready"


class _TaskNode:
    __slots__ = ("tid", "kind", "out")

    def __init__(self, tid: str, kind: str) -> None:
        self.tid = tid
        self.kind = kind
        self.out: list[_TaskNode] = []


def _sorted_out(nd: _TaskNode) -> list[_TaskNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.tid)
    return kids


def _find_task(tid: str, store: dict) -> _TaskNode | None:
    nmap = store["nodes"]
    if tid in nmap:
        return nmap[tid]
    return None


def _reach_order(start_id: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    queue: deque[str] = deque([start_id])
    nodes = store["nodes"]
    while queue:
        tid = queue.popleft()
        if tid in claimed:
            continue
        claimed[tid] = True
        order.append(tid)
        nd = nodes.get(tid)
        if nd is not None:
            for child in reversed(_sorted_out(nd)):
                queue.appendleft(child.tid)
    return order


def fresh_release_store() -> dict:
    return {"tasks": {}, "kinds": {}, "deps": {}, "rev": {}, "nodes": {}, "roots": []}


def register_task(tid: str, kind: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_release_store()
    s["tasks"][tid] = True
    s["kinds"][tid] = kind
    outs = s["deps"]
    if tid not in outs:
        outs[tid] = []
    revs = s["rev"]
    if tid not in revs:
        revs[tid] = []
    nd = _TaskNode(tid=tid, kind=kind)
    s["roots"].append(tid)
    s["nodes"][tid] = nd
    return s


def add_task_dep(source_id: str, target_id: str, store: dict) -> None:
    tmap = store["tasks"]
    if source_id not in tmap or target_id not in tmap:
        raise KeyError("unknown task id")
    if source_id == target_id:
        return
    src_nd = _find_task(source_id, store)
    tgt_nd = _find_task(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.tid == target_id for ex in src_nd.out)
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


def direct_deps(task_id: str, store: dict) -> list[str]:
    if task_id not in store["tasks"]:
        raise KeyError(task_id)
    return list(store["deps"].get(task_id, []))


def release_topology(start_id: str, store: dict) -> list[str]:
    if start_id not in store["tasks"]:
        raise KeyError(start_id)
    start_nd = _find_task(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for tid in _reach_order(start_id, store):
        if tid != start_id:
            reach.append(tid)
    reach = sorted(reach)
    return reach


def chart_gate_status(open_blockers: int) -> str:
    if open_blockers > 0:
        return STATUS_BLOCKED
    return STATUS_READY


def release_report(start_id: str, store: dict, open_blockers: int) -> dict:
    if start_id not in store["tasks"]:
        raise KeyError(start_id)
    topo = release_topology(start_id, store)
    direct = direct_deps(start_id, store)
    gate = chart_gate_status(open_blockers)
    kinds = store["kinds"]
    wf = 0
    doc = 0
    ex = 0
    gt = 0
    for tid in topo:
        k = kinds.get(tid, "")
        if k == KIND_WORKFLOW:
            wf += 1
        if k == KIND_DOCS:
            doc += 1
        if k == KIND_EXAMPLE:
            ex += 1
        if k == KIND_GATE:
            gt += 1
    return {
        "gate": gate,
        "direct": direct,
        "topology": topo,
        "topology_count": len(topo),
        "workflow_tasks": wf,
        "docs_tasks": doc,
        "example_tasks": ex,
        "gate_tasks": gt,
    }
