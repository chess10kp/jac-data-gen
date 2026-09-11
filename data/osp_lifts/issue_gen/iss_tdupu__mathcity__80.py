"""tdupu/mathcity#80 — stale inactive workflow issue root candidates (reaper CTE).

The reaper order times out on WITH RECURSIVE workflow_issue_root_candidates_base over
issues joined to wisp dependency metadata. Hand-rolled adjacency dict, deque ascent,
and parent-child dominance checks stand in for the recursive CTE.
"""

from __future__ import annotations

from collections import defaultdict, deque


class WorkflowStore:
    def __init__(self) -> None:
        self._status: dict[str, str] = {}
        self._tier: dict[str, str] = {}
        self._deps: dict[str, list[tuple[str, str]]] = defaultdict(list)


def load_workflow_store(
    statuses: dict[str, str],
    tiers: dict[str, str],
    edges: list[tuple[str, str, str]],
) -> WorkflowStore:
    store = WorkflowStore()
    store._status = dict(statuses)
    store._tier = dict(tiers)
    for src, dst, kind in edges:
        if src in store._status and dst in store._status:
            store._deps[src].append((dst, kind))
    return store


def dependency_ascent(store: WorkflowStore, start_id: str) -> list[str]:
    if start_id not in store._status:
        return []
    claimed: set[str] = set()
    work: deque[str] = deque([start_id])
    hits: set[str] = set()
    while work:
        cur = work.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        for tgt, _kind in store._deps.get(cur, []):
            if tgt not in claimed:
                work.append(tgt)
                if tgt != start_id:
                    hits.add(tgt)
    return sorted(hits)


def workflow_issue_root_candidates(store: WorkflowStore, start_id: str) -> list[str]:
    if start_id not in store._status:
        return []
    claimed: set[str] = {start_id}
    work: deque[str] = deque([start_id])
    issues: set[str] = set()
    while work:
        cur = work.popleft()
        if store._tier.get(cur, "issue") == "issue":
            issues.add(cur)
        for tgt, _kind in store._deps.get(cur, []):
            if tgt not in claimed:
                claimed.add(tgt)
                work.append(tgt)
    dominated: set[str] = set()
    for src in claimed:
        if store._tier.get(src, "issue") != "issue":
            continue
        for tgt, kind in store._deps.get(src, []):
            if kind == "parent-child" and tgt in issues:
                dominated.add(src)
    return sorted(i for i in issues if i not in dominated)


def stale_inactive_issue_ids(store: WorkflowStore) -> list[str]:
    return sorted(
        nid
        for nid, st in store._status.items()
        if store._tier.get(nid, "issue") == "issue" and st == "inactive"
    )


def reaper_visit_count(store: WorkflowStore, start_id: str) -> int:
    if start_id not in store._status:
        return 0
    claimed: set[str] = set()
    work: deque[str] = deque([start_id])
    steps = 0
    while work:
        cur = work.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        steps += 1
        for tgt, _kind in store._deps.get(cur, []):
            if tgt not in claimed:
                work.append(tgt)
    return steps
