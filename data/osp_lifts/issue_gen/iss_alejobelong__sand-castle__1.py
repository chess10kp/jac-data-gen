"""alejobelong/sand-castle#1 — sandcastle-synth slice DAG scheduler and lineage reach."""

from __future__ import annotations

from collections import deque


class CycleError(Exception):
    pass


class PlanHandle:
    def __init__(self) -> None:
        self._slices: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._max_concurrency: int = 1


def load_plan(
    slice_ids: list[str],
    depends_edges: list[tuple[str, str]],
    *,
    max_concurrency: int = 1,
) -> PlanHandle:
    plan = PlanHandle()
    plan._max_concurrency = max(1, max_concurrency)
    for sid in slice_ids:
        plan._slices.add(sid)
        plan._depends.setdefault(sid, [])
    for upstream, downstream in depends_edges:
        if upstream not in plan._slices or downstream not in plan._slices:
            raise KeyError("unknown slice")
        plan._depends.setdefault(downstream, []).append(upstream)
    return plan


def topological_levels(plan: PlanHandle) -> list[list[str]]:
    indegree: dict[str, int] = {s: len(plan._depends.get(s, [])) for s in plan._slices}
    rev: dict[str, list[str]] = {s: [] for s in plan._slices}
    for downstream, ups in plan._depends.items():
        for up in ups:
            rev[up].append(downstream)
    levels: list[list[str]] = []
    visited: set[str] = set()
    ready = {s for s, d in indegree.items() if d == 0}
    while ready:
        layer = sorted(ready)
        levels.append(layer)
        next_ready: set[str] = set()
        for node in layer:
            visited.add(node)
            for other in rev.get(node, []):
                indegree[other] -= 1
                if indegree[other] == 0 and other not in visited:
                    next_ready.add(other)
        ready = next_ready
    if len(visited) != len(plan._slices):
        raise CycleError("cycle in slice dependencies")
    return levels


def downstream_reach(plan: PlanHandle, root: str) -> list[str]:
    if root not in plan._slices:
        return []
    rev: dict[str, list[str]] = {s: [] for s in plan._slices}
    for downstream, ups in plan._depends.items():
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


def upstream_closure(plan: PlanHandle, root: str) -> list[str]:
    if root not in plan._slices:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque(plan._depends.get(root, []))
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for dep in plan._depends.get(cur, []):
            queue.append(dep)
    return sorted(seen)


def ready_slices(plan: PlanHandle, completed: list[str] | None = None) -> list[str]:
    done = set(completed or [])
    ready: list[str] = []
    for sid in sorted(plan._slices):
        if sid in done:
            continue
        deps = plan._depends.get(sid, [])
        if all(d in done for d in deps):
            ready.append(sid)
    return ready


def schedule_batches(plan: PlanHandle, completed: list[str] | None = None) -> list[list[str]]:
    batches: list[list[str]] = []
    done = set(completed or [])
    while True:
        ready = ready_slices(plan, sorted(done))
        if not ready:
            break
        batch = ready[: plan._max_concurrency]
        batches.append(batch)
        done.update(batch)
    return batches
