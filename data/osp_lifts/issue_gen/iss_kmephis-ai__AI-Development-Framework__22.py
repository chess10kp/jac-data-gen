"""kmephis-ai/AI-Development-Framework#22 — Foundation roadmap DAG and trace reach."""

from __future__ import annotations

from collections import deque

STATUS_COMPLETED = "COMPLETED"
TRACE_REQUIREMENT = "requirement"
TRACE_DECISION = "decision"


class RoadmapTask:
    def __init__(self, task_id: str, status: str) -> None:
        self.task_id = task_id
        self.status = status


class FoundationStore:
    def __init__(self) -> None:
        self.tasks: dict[str, RoadmapTask] = {}
        self._downstream: dict[str, list[str]] = {}
        self._trace_refs: dict[str, list[tuple[str, str, str]]] = {}


def _downstream_ids(store: FoundationStore, start_id: str) -> list[str]:
    if start_id not in store.tasks:
        return []
    visited: set[str] = set()
    order: list[str] = []
    stack: list[str] = [start_id]
    while stack:
        cur = stack.pop()
        if cur in visited:
            continue
        visited.add(cur)
        order.append(cur)
        kids = sorted(store._downstream.get(cur, []))
        i = len(kids) - 1
        while i >= 0:
            stack.append(kids[i])
            i -= 1
    return order


def _upstream_ids(store: FoundationStore, start_id: str) -> list[str]:
    if start_id not in store.tasks:
        return []
    visited: set[str] = set()
    order: list[str] = []
    stack: list[str] = [start_id]
    while stack:
        cur = stack.pop()
        if cur in visited:
            continue
        visited.add(cur)
        order.append(cur)
        parents: list[str] = []
        for up, downs in store._downstream.items():
            if cur in downs:
                parents.append(up)
        parents = sorted(parents)
        i = len(parents) - 1
        while i >= 0:
            stack.append(parents[i])
            i -= 1
    return order


def fresh_foundation_store() -> FoundationStore:
    return FoundationStore()


def register_task(
    task_id: str,
    status: str,
    store: FoundationStore | None = None,
) -> FoundationStore:
    s = store
    if s is None:
        s = fresh_foundation_store()
    if task_id in s.tasks:
        raise ValueError("duplicate task id")
    s.tasks[task_id] = RoadmapTask(task_id=task_id, status=status)
    s._downstream.setdefault(task_id, [])
    s._trace_refs.setdefault(task_id, [])
    return s


def add_task_dependency(upstream_id: str, downstream_id: str, store: FoundationStore) -> None:
    if upstream_id not in store.tasks or downstream_id not in store.tasks:
        raise KeyError("unknown task id")
    if upstream_id == downstream_id:
        raise ValueError("self dependency")
    for jid in _downstream_ids(store, downstream_id):
        if jid == upstream_id:
            raise ValueError("cycle")
    outs = store._downstream.setdefault(upstream_id, [])
    if downstream_id not in outs:
        outs.append(downstream_id)
        outs.sort()


def add_trace_ref(task_id: str, entity_id: str, kind: str, rel: str, store: FoundationStore) -> None:
    if task_id not in store.tasks:
        raise KeyError("unknown task id")
    refs = store._trace_refs.setdefault(task_id, [])
    refs.append((entity_id, kind, rel))


def downstream_closure(task_id: str, store: FoundationStore) -> list[str]:
    if task_id not in store.tasks:
        raise KeyError(task_id)
    reach: list[str] = []
    for tid in _downstream_ids(store, task_id):
        if tid != task_id:
            reach.append(tid)
    return sorted(reach)


def upstream_closure(task_id: str, store: FoundationStore) -> list[str]:
    if task_id not in store.tasks:
        raise KeyError(task_id)
    reach: list[str] = []
    for tid in _upstream_ids(store, task_id):
        if tid != task_id:
            reach.append(tid)
    return sorted(reach)


def critical_path_order(store: FoundationStore) -> list[str] | None:
    indeg: dict[str, int] = {}
    for tid in store.tasks:
        indeg[tid] = 0
    for upstream, outs in store._downstream.items():
        for succ in outs:
            indeg[succ] = indeg.get(succ, 0) + 1
    order: list[str] = []
    total = len(indeg)
    while len(order) < total:
        picked: list[str] = []
        for tid in sorted(indeg.keys()):
            if indeg[tid] == 0:
                picked.append(tid)
        if not picked:
            return None
        for nid in picked:
            order.append(nid)
            for succ in store._downstream.get(nid, []):
                indeg[succ] -= 1
            indeg[nid] = -1
    return order


def trace_refs_for_task(task_id: str, store: FoundationStore) -> list[tuple[str, str, str]]:
    if task_id not in store.tasks:
        raise KeyError(task_id)
    return sorted(store._trace_refs.get(task_id, []))


def validate_foundation_dag(store: FoundationStore) -> list[tuple[str, str]]:
    if critical_path_order(store) is None:
        return [("cycle", "detected")]
    return []
