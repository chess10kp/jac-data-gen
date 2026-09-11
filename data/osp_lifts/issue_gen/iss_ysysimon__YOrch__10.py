"""ysysimon/YOrch#10 — Task DAG compile planning with cycle rejection."""

from __future__ import annotations

from collections import deque


class TaskGraph:
    def __init__(self) -> None:
        self._tasks: set[str] = set()
        self._deps: dict[str, set[str]] = {}
        self._dependents: dict[str, set[str]] = {}


def load_task_graph(
    tasks: list[str],
    depends: list[tuple[str, str]],
) -> TaskGraph:
    g = TaskGraph()
    for t in tasks:
        g._tasks.add(t)
        g._deps.setdefault(t, set())
        g._dependents.setdefault(t, set())
    for task, dep in depends:
        if task not in g._tasks:
            continue
        if dep not in g._tasks:
            raise KeyError(f"invalid dependency: {dep}")
        g._deps[task].add(dep)
        g._dependents[dep].add(task)
    return g


def compile_plan(g: TaskGraph) -> list[str]:
    indeg = {t: len(g._deps[t]) for t in g._tasks}
    q: deque[str] = deque(sorted(t for t, d in indeg.items() if d == 0))
    out: list[str] = []
    while q:
        cur = q.popleft()
        out.append(cur)
        for dep in sorted(g._dependents.get(cur, ())):
            indeg[dep] -= 1
            if indeg[dep] == 0:
                q.append(dep)
    if len(out) != len(g._tasks):
        raise ValueError("cycle")
    return out


def ready_after(g: TaskGraph, completed: list[str]) -> list[str]:
    done = set(completed)
    ready: list[str] = []
    for task in sorted(g._tasks):
        if task in done:
            continue
        if g._deps[task].issubset(done):
            ready.append(task)
    return ready
