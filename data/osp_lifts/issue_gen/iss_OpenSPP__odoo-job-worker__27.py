"""OpenSPP/odoo-job-worker#27 — raw-SQL parent cascade is single-level."""

from __future__ import annotations

from collections import deque

TERMINAL = frozenset({"done", "failed", "cancelled"})


class JobRegistry:
    def __init__(self) -> None:
        self.jobs: dict[str, dict[str, str | None]] = {}
        self.children_of: dict[str, list[str]] = {}


def build_job_registry(rows: list[dict]) -> JobRegistry:
    reg = JobRegistry()
    for row in rows:
        jid = row["id"]
        reg.jobs[jid] = {
            "parent_id": row.get("parent_id"),
            "status": row.get("status", "waiting"),
        }
        reg.children_of.setdefault(jid, [])
    for jid, meta in reg.jobs.items():
        pid = meta["parent_id"]
        if pid is not None and pid in reg.jobs:
            reg.children_of.setdefault(pid, []).append(jid)
    for pid in reg.children_of:
        reg.children_of[pid] = sorted(reg.children_of[pid])
    return reg


def direct_children(registry: JobRegistry, parent_id: str) -> list[str]:
    if parent_id not in registry.jobs:
        return []
    return list(registry.children_of.get(parent_id, []))


def descendant_job_ids(registry: JobRegistry, root: str) -> list[str]:
    if root not in registry.jobs:
        return []
    seen: set[str] = set()
    q: deque[str] = deque(registry.children_of.get(root, []))
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for ch in registry.children_of.get(cur, []):
            if ch not in seen:
                q.append(ch)
    return sorted(seen)


def raw_sql_parent_cascade(registry: JobRegistry, failed_parent_id: str) -> list[str]:
    # Single-level UPDATE ... WHERE parent_id = failed_parent (cli/worker.py path).
    if failed_parent_id not in registry.jobs:
        return []
    changed: list[str] = []
    for child in registry.children_of.get(failed_parent_id, []):
        if registry.jobs[child]["status"] == "waiting":
            registry.jobs[child]["status"] = "failed"
            changed.append(child)
    return sorted(changed)


def orm_cascade_children_on_parent_failure(
    registry: JobRegistry, failed_parent_id: str
) -> list[str]:
    # ORM path: queue-walk newly failed nodes until no waiting descendants remain.
    if failed_parent_id not in registry.jobs:
        return []
    changed: list[str] = []
    q: deque[str] = deque([failed_parent_id])
    while q:
        parent = q.popleft()
        for child in registry.children_of.get(parent, []):
            if registry.jobs[child]["status"] == "waiting":
                registry.jobs[child]["status"] = "failed"
                changed.append(child)
                q.append(child)
    return sorted(changed)


def reclaim_exhausted_cascade(registry: JobRegistry, job_id: str) -> dict[str, list[str]]:
    if job_id not in registry.jobs:
        return {"failed": [], "cascaded": []}
    registry.jobs[job_id]["status"] = "failed"
    cascaded = raw_sql_parent_cascade(registry, job_id)
    return {"failed": [job_id], "cascaded": cascaded}


def gc_collectible_ids(registry: JobRegistry) -> list[str]:
    return sorted(jid for jid, meta in registry.jobs.items() if meta["status"] in TERMINAL)


def stuck_waiting_jobs(registry: JobRegistry) -> list[str]:
    stuck: list[str] = []
    for jid, meta in registry.jobs.items():
        if meta["status"] != "waiting":
            continue
        cur = meta["parent_id"]
        seen: set[str] = set()
        while cur is not None:
            if cur in seen:
                break
            seen.add(cur)
            parent_meta = registry.jobs.get(cur)
            if parent_meta is None:
                break
            if parent_meta["status"] == "failed":
                stuck.append(jid)
                break
            cur = parent_meta["parent_id"]
    return sorted(stuck)
