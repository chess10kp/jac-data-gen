"""kagura-agent/cove#471 — Task workflow dependency scheduling with cascade skip."""

from __future__ import annotations


class WorkflowBoard:
    def __init__(self) -> None:
        self._tasks: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._status: dict[str, str] = {}


def load_workflow(
    tasks: list[str],
    deps: list[tuple[str, str]],
) -> WorkflowBoard:
    b = WorkflowBoard()
    for tid in tasks:
        b._tasks.add(tid)
        b._depends.setdefault(tid, [])
        b._status[tid] = "open"
    for blocker, task in deps:
        if blocker in b._tasks and task in b._tasks:
            b._depends.setdefault(task, []).append(blocker)
    return b


def ready_tasks(board: WorkflowBoard) -> list[str]:
    ready: list[str] = []
    for tid in sorted(board._tasks):
        if board._status.get(tid) != "open":
            continue
        blockers = board._depends.get(tid, [])
        if all(board._status.get(b) == "done" for b in blockers):
            ready.append(tid)
    return ready


def _collect_dependents(board: WorkflowBoard, root: str) -> list[str]:
    stack = [root]
    seen: set[str] = set()
    out: list[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for tid in board._tasks:
            if cur in board._depends.get(tid, []) and tid not in seen:
                stack.append(tid)
    return out


def mark_failed(board: WorkflowBoard, task_id: str) -> list[str]:
    if task_id not in board._tasks:
        return []
    board._status[task_id] = "failed"
    skipped: list[str] = []
    for tid in _collect_dependents(board, task_id):
        if tid == task_id:
            continue
        if board._status.get(tid) == "open":
            board._status[tid] = "skipped"
            skipped.append(tid)
    return sorted(skipped)


def mark_done(board: WorkflowBoard, task_id: str) -> None:
    if task_id in board._tasks:
        board._status[task_id] = "done"
