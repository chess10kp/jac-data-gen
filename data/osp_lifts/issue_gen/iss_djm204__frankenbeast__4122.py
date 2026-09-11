"""djm204/frankenbeast#4122 — PlanGraph sub-task validation with cycle detection.

Hand-rolled task dependency adjacency plus recursive cycle probe before
returning a validated topological order from _buildSubGraph.
"""

from __future__ import annotations

from collections import deque


class CyclicDependencyError(Exception):
    pass


class PlanGraph:
    def __init__(self) -> None:
        self.tasks: set[str] = set()
        self.depends: dict[str, list[str]] = {}


def load_plan(
    tasks: list[str],
    edges: list[tuple[str, str]],
) -> PlanGraph:
    g = PlanGraph()
    for tid in tasks:
        g.tasks.add(tid)
        g.depends.setdefault(tid, [])
    for task, dep in edges:
        if task in g.tasks and dep in g.tasks:
            g.depends[task].append(dep)
    return g


def _has_cycle(g: PlanGraph) -> bool:
    state: dict[str, int] = {t: 0 for t in g.tasks}
    stack: list[str] = []

    def dfs(node: str) -> bool:
        state[node] = 1
        stack.append(node)
        for nxt in g.depends.get(node, []):
            if state[nxt] == 1:
                return True
            if state[nxt] == 0 and dfs(nxt):
                return True
        stack.pop()
        state[node] = 2
        return False

    for tid in sorted(g.tasks):
        if state[tid] == 0 and dfs(tid):
            return True
    return False


def validate_plan(g: PlanGraph) -> list[str]:
    if _has_cycle(g):
        raise CyclicDependencyError("cyclic sub-graph")
    indeg: dict[str, int] = {t: 0 for t in g.tasks}
    for task in g.tasks:
        for dep in g.depends.get(task, []):
            indeg[task] += 1
    q: deque[str] = deque(sorted(t for t in g.tasks if indeg[t] == 0))
    order: list[str] = []
    while q:
        cur = q.popleft()
        order.append(cur)
        for task in sorted(g.tasks):
            if cur in g.depends.get(task, []):
                indeg[task] -= 1
                if indeg[task] == 0:
                    q.append(task)
    if len(order) != len(g.tasks):
        raise CyclicDependencyError("cyclic sub-graph")
    return order


def build_subgraph(g: PlanGraph, task_ids: list[str]) -> list[str]:
    keep = {t for t in task_ids if t in g.tasks}
    sub = PlanGraph()
    for tid in keep:
        sub.tasks.add(tid)
        sub.depends[tid] = [d for d in g.depends.get(tid, []) if d in keep]
    return validate_plan(sub)
