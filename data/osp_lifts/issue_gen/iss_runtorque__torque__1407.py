"""runtorque/torque#1407 — Completion-blocker query excludes auto-expirable engineer messages."""

from __future__ import annotations

from collections import deque


class BoardStore:
    def __init__(self) -> None:
        self._tasks: dict[str, dict[str, object]] = {}
        self._children: dict[str, list[str]] = {}


def load_board(
    tasks: list[tuple[str, str, list[str]]],
    child_edges: list[tuple[str, str]],
) -> BoardStore:
    g = BoardStore()
    for tid, status, labels in tasks:
        g._tasks[tid] = {"status": status, "labels": list(labels)}
        g._children.setdefault(tid, [])
    for parent, child in child_edges:
        if parent not in g._tasks or child not in g._tasks:
            continue
        g._children.setdefault(parent, []).append(child)
        g._children.setdefault(child, g._children.get(child, []))
    return g


def task_is_engineer_message_followup(store: BoardStore, task_id: str) -> bool:
    row = store._tasks.get(task_id)
    if row is None:
        return False
    labels = row.get("labels", [])
    return "torque:engineer-message" in labels


def _is_open(store: BoardStore, task_id: str) -> bool:
    row = store._tasks.get(task_id)
    return row is not None and row["status"] != "Done"


def task_open_descendants(store: BoardStore, task_id: str) -> list[str]:
    if task_id not in store._tasks:
        return []
    seen: set[str] = set()
    work: deque[str] = deque([task_id])
    open_ids: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for ch in store._children.get(cur, []):
            if ch in seen:
                continue
            if _is_open(store, ch):
                open_ids.append(ch)
            work.append(ch)
    return sorted(open_ids)


def task_has_unresolved_descendants(store: BoardStore, task_id: str) -> bool:
    return bool(task_open_descendants(store, task_id))


def task_has_unresolved_completion_blockers(store: BoardStore, task_id: str) -> bool:
    for tid in task_open_descendants(store, task_id):
        if not task_is_engineer_message_followup(store, tid):
            return True
    return False
