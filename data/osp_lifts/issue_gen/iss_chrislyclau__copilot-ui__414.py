"""chrislyclau/copilot-ui#414 — Task dependency graph + Planner decomposition."""

from __future__ import annotations

from collections import deque

CYCLE_WALK_LIMIT = 64


class PlannerGraph:
    def __init__(self) -> None:
        self._tasks: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._blockers: dict[str, set[str]] = {}
        self._dependents: dict[str, set[str]] = {}


def load_planner(
    tasks: list[str],
    parent_edges: list[tuple[str, str]],
    deps: list[tuple[str, str]] | None = None,
) -> PlannerGraph:
    g = PlannerGraph()
    for tid in tasks:
        g._tasks.add(tid)
        g._parent[tid] = None
        g._children.setdefault(tid, [])
        g._blockers.setdefault(tid, set())
        g._dependents.setdefault(tid, set())
    for child, parent in parent_edges:
        if child not in g._tasks or parent not in g._tasks:
            continue
        g._parent[child] = parent
        g._children.setdefault(parent, []).append(child)
    for blocker, dependent in deps or []:
        if blocker in g._tasks and dependent in g._tasks:
            g._blockers[dependent].add(blocker)
            g._dependents[blocker].add(dependent)
    return g


def _bfs_reaches(g: PlannerGraph, start: str, target: str) -> bool:
    q: deque[str] = deque([start])
    seen: set[str] = set()
    steps = 0
    while q and steps < CYCLE_WALK_LIMIT:
        cur = q.popleft()
        if cur == target:
            return True
        if cur in seen:
            continue
        seen.add(cur)
        steps += 1
        for nxt in g._dependents.get(cur, ()):
            if nxt not in seen:
                q.append(nxt)
    return False


def add_dependency(g: PlannerGraph, blocker: str, dependent: str) -> None:
    if blocker not in g._tasks or dependent not in g._tasks:
        raise KeyError("unknown task")
    if blocker == dependent:
        raise ValueError("self edge")
    if blocker in g._blockers[dependent]:
        raise ValueError("duplicate edge")
    if _bfs_reaches(g, dependent, blocker):
        raise ValueError("cycle")
    g._blockers[dependent].add(blocker)
    g._dependents[blocker].add(dependent)


def remove_dependency(g: PlannerGraph, blocker: str, dependent: str) -> None:
    if dependent not in g._tasks:
        raise KeyError("unknown task")
    g._blockers[dependent].discard(blocker)
    g._dependents.get(blocker, set()).discard(dependent)


def is_blocked(
    g: PlannerGraph,
    task_id: str,
    statuses: dict[str, str],
    read_error: bool = False,
) -> bool:
    if read_error:
        return True
    if task_id not in g._tasks:
        return True
    for b in g._blockers[task_id]:
        if statuses.get(b) != "done":
            return True
    return False


def subtree_tasks(g: PlannerGraph, root_id: str) -> list[str]:
    if root_id not in g._tasks:
        return []
    q: deque[str] = deque([root_id])
    claimed: set[str] = set()
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for ch in g._children.get(cur, []):
            if ch not in claimed:
                q.append(ch)
    return sorted(hits)


def dependent_closure(g: PlannerGraph, task_id: str) -> list[str]:
    if task_id not in g._tasks:
        return []
    stack = [task_id]
    seen: set[str] = set()
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        stack.extend(g._dependents.get(cur, ()))
    return sorted(seen)
