"""dotflow-io/dotflow#288 — DAG executor with topological levels and cascade removal."""

from __future__ import annotations

from collections import deque


class CycleError(Exception):
    pass


class DagExecutor:
    # Adjacency dict mapping steps to upstream depends_on sets.
    def __init__(self) -> None:
        self._steps: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._active: dict[str, bool] = {}


def load_dag(
    step_names: list[str],
    depends_edges: list[tuple[str, str]],
) -> DagExecutor:
    dag = DagExecutor()
    for step in step_names:
        dag._steps.add(step)
        dag._depends.setdefault(step, [])
        dag._active[step] = True
    for upstream, downstream in depends_edges:
        if upstream in dag._steps and downstream in dag._steps:
            dag._depends.setdefault(downstream, []).append(upstream)
    return dag


def topological_levels(store: DagExecutor) -> list[list[str]]:
    indegree: dict[str, int] = {n: 0 for n in store._steps}
    for node, deps in store._depends.items():
        for _ in deps:
            indegree[node] += 1
    levels: list[list[str]] = []
    ready = {n for n, d in indegree.items() if d == 0}
    visited: set[str] = set()
    while ready:
        levels.append(sorted(ready))
        next_ready: set[str] = set()
        for node in ready:
            visited.add(node)
            for other, deps in store._depends.items():
                if node in deps and other not in visited:
                    indegree[other] -= 1
                    if indegree[other] == 0:
                        next_ready.add(other)
        ready = next_ready
    if len(visited) != len(store._steps):
        raise CycleError(store._depends)
    return levels


def _dependents_of(store: DagExecutor, root: str) -> list[str]:
    rev: dict[str, list[str]] = {s: [] for s in store._steps}
    for downstream, ups in store._depends.items():
        for up in ups:
            rev[up].append(downstream)
    seen: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for nxt in rev.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def remove_step(store: DagExecutor, step: str) -> list[str]:
    if step not in store._steps:
        return []
    targets = _dependents_of(store, step)
    removed = [step] + targets
    for sid in removed:
        store._active[sid] = False
    return sorted(removed)


def active_steps(store: DagExecutor) -> list[str]:
    return sorted(s for s, on in store._active.items() if on)
