"""k-nuth/kth#624 — CI workflow DAG downstream closure and cache diagnosis."""
from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field

PLATFORM_MACOS = "macos"
CACHE_RESTORED = "restored"
CACHE_MISSED = "missed"


@dataclass
class BuildJob:
    job_id: str
    platform: str
    compile_secs: int
    test_secs: int
    ccache_hit_rate: float
    cache_state: str


@dataclass
class WorkflowStore:
    jobs: dict[str, BuildJob] = field(default_factory=dict)
    downstream: dict[str, list[str]] = field(default_factory=dict)


def _sorted_downstream(store: WorkflowStore, job_id: str) -> list[str]:
    return sorted(store.downstream.get(job_id, []))


def _downstream_ids(store: WorkflowStore, start_id: str) -> list[str]:
    if start_id not in store.jobs:
        return []
    claimed: dict[str, bool] = {}
    ids: list[str] = []
    stack: list[str] = [start_id]
    while stack:
        jid = stack.pop()
        if jid in claimed:
            continue
        claimed[jid] = True
        ids.append(jid)
        kids = _sorted_downstream(store, jid)
        i = len(kids) - 1
        while i >= 0:
            stack.append(kids[i])
            i -= 1
    return ids


def fresh_workflow_store() -> WorkflowStore:
    return WorkflowStore()


def register_job(
    job_id: str,
    platform: str,
    compile_secs: int,
    test_secs: int,
    ccache_hit_rate: float,
    cache_state: str,
    store: WorkflowStore | None = None,
) -> WorkflowStore:
    s = store if store is not None else fresh_workflow_store()
    if job_id in s.jobs:
        raise ValueError("duplicate job id")
    s.jobs[job_id] = BuildJob(
        job_id=job_id,
        platform=platform,
        compile_secs=compile_secs,
        test_secs=test_secs,
        ccache_hit_rate=ccache_hit_rate,
        cache_state=cache_state,
    )
    s.downstream.setdefault(job_id, [])
    return s


def add_job_dependency(upstream_id: str, downstream_id: str, store: WorkflowStore) -> None:
    if upstream_id not in store.jobs or downstream_id not in store.jobs:
        raise KeyError("unknown job id")
    if upstream_id == downstream_id:
        raise ValueError("self dependency")
    for jid in _downstream_ids(store, downstream_id):
        if jid == upstream_id:
            raise ValueError("cycle")
    downs = store.downstream.setdefault(upstream_id, [])
    if downstream_id not in downs:
        downs.append(downstream_id)


def direct_downstream_jobs(job_id: str, store: WorkflowStore) -> list[str]:
    if job_id not in store.jobs:
        raise KeyError(job_id)
    return _sorted_downstream(store, job_id)


def downstream_closure(job_id: str, store: WorkflowStore) -> list[str]:
    if job_id not in store.jobs:
        raise KeyError(job_id)
    reach = [jid for jid in _downstream_ids(store, job_id) if jid != job_id]
    return sorted(reach)


def workflow_build_order(store: WorkflowStore) -> list[str] | None:
    indeg: dict[str, int] = {jid: 0 for jid in store.jobs}
    for up in store.jobs:
        for down in store.downstream.get(up, []):
            indeg[down] += 1
    order: list[str] = []
    total = len(indeg)
    while len(order) < total:
        ready = deque(jid for jid in sorted(indeg) if indeg[jid] == 0)
        if not ready:
            return None
        while ready:
            nid = ready.popleft()
            order.append(nid)
            for succ in store.downstream.get(nid, []):
                indeg[succ] -= 1
            indeg[nid] = -1
    return order


def invalidate_downstream_on_rerun(root_job_id: str, store: WorkflowStore) -> list[str]:
    if root_job_id not in store.jobs:
        raise KeyError(root_job_id)
    return sorted(_downstream_ids(store, root_job_id))


def cache_diagnosis(job_id: str, store: WorkflowStore) -> str:
    if job_id not in store.jobs:
        return "reject_unknown"
    nd = store.jobs[job_id]
    if nd.cache_state == CACHE_MISSED or nd.ccache_hit_rate < 0.5:
        return "cache_miss"
    return "healthy"


def timing_variance_ratio(slow_compile_secs: int, normal_compile_secs: int) -> float:
    if normal_compile_secs <= 0:
        return 0.0
    return slow_compile_secs / normal_compile_secs
