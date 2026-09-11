"""johnjansen/claudeclaw#44 — Job dependency DAG execution."""

from __future__ import annotations

from collections import deque


class JobBoard:
    def __init__(self) -> None:
        self._jobs: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._done: set[str] = set()
        self._failed: set[str] = set()


def load_job_board(
    jobs: list[str],
    deps: list[tuple[str, str]],
    done: list[str] | None = None,
    failed: list[str] | None = None,
) -> JobBoard:
    b = JobBoard()
    for jid in jobs:
        b._jobs.add(jid)
        b._depends.setdefault(jid, [])
    for prereq, job in deps:
        if prereq in b._jobs and job in b._jobs:
            b._depends.setdefault(job, []).append(prereq)
    b._done = set(done or [])
    b._failed = set(failed or [])
    return b


def detect_cycles(board: JobBoard) -> list[tuple[str, str]]:
    errors: list[tuple[str, str]] = []
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> None:
        visited.add(node)
        stack.add(node)
        for nxt in board._depends.get(node, []):
            if nxt in stack:
                errors.append((node, nxt))
            elif nxt not in visited:
                dfs(nxt)
        stack.remove(node)

    for jid in sorted(board._jobs):
        if jid not in visited:
            dfs(jid)
    return sorted(errors)


def get_ready_jobs(board: JobBoard) -> list[str]:
    ready: list[str] = []
    for jid in sorted(board._jobs):
        if jid in board._done or jid in board._failed:
            continue
        blockers = [
            p
            for p in board._depends.get(jid, [])
            if p not in board._done and p not in board._failed
        ]
        if not blockers:
            ready.append(jid)
    return ready


def execution_order(board: JobBoard) -> list[str]:
    # Kahn topological sort over depends edges (prereq -> job).
    indeg: dict[str, int] = {j: 0 for j in board._jobs}
    rev: dict[str, list[str]] = {j: [] for j in board._jobs}
    for job in board._jobs:
        for prereq in board._depends.get(job, []):
            indeg[job] += 1
            rev[prereq].append(job)
    queue: deque[str] = deque(sorted(j for j in board._jobs if indeg[j] == 0))
    order: list[str] = []
    while queue:
        cur = queue.popleft()
        order.append(cur)
        for nxt in sorted(rev.get(cur, [])):
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                queue.append(nxt)
    return order if len(order) == len(board._jobs) else []
