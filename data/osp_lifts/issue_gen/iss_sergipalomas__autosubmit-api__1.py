"""sergipalomas/autosubmit-api#1 — Experiment job dependency readiness graph.

Workflow jobs declare blocked-by edges; stack walk gathers prerequisite job
IDs before overlap-aware critical-path metrics may run.
"""

from __future__ import annotations


class JobGraph:
    def __init__(self) -> None:
        self.jobs: set[str] = set()
        self.blocked_by: dict[str, list[str]] = {}


def load_job_graph(
    jobs: list[str],
    block_edges: list[tuple[str, str]],
) -> JobGraph:
    g = JobGraph()
    for jid in jobs:
        g.jobs.add(jid)
        g.blocked_by.setdefault(jid, [])
    for blocker, blocked in block_edges:
        if blocker in g.jobs and blocked in g.jobs:
            g.blocked_by.setdefault(blocked, []).append(blocker)
    return g


def _upstream(g: JobGraph, job_id: str) -> set[str]:
    seen: set[str] = set()
    stack: list[str] = [job_id]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for blk in sorted(g.blocked_by.get(cur, [])):
            stack.append(blk)
    return seen


def critical_predecessors(g: JobGraph, job_id: str) -> list[str]:
    if job_id not in g.jobs:
        return []
    return sorted(_upstream(g, job_id))


def ready_jobs(g: JobGraph, finished: list[str]) -> list[str]:
    done = set(finished)
    ready: list[str] = []
    for jid in sorted(g.jobs):
        if jid in done:
            continue
        needs = [p for p in critical_predecessors(g, jid) if p != jid]
        if all(p in done for p in needs):
            ready.append(jid)
    return ready
