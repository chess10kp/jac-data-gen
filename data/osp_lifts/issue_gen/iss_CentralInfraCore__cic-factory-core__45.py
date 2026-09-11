"""CentralInfraCore/cic-factory-core#45 — Factory task dependency readiness walk.

Hand-rolled blocked-by adjacency + queue upstream walk for FC wave ordering
before executor conformance gates land.
"""

from __future__ import annotations

from collections import deque


class FactoryPlan:
    def __init__(self) -> None:
        self._tasks: set[str] = set()
        self._blocked_by: dict[str, list[str]] = {}


def load_plan(
    tasks: list[str],
    edges: list[tuple[str, str]],
) -> FactoryPlan:
    plan = FactoryPlan()
    for tid in tasks:
        plan._tasks.add(tid)
        plan._blocked_by.setdefault(tid, [])
    for blocker, blocked in edges:
        if blocker in plan._tasks and blocked in plan._tasks:
            plan._blocked_by.setdefault(blocked, []).append(blocker)
    return plan


def blocked_by(plan: FactoryPlan, task_id: str) -> list[str]:
    if task_id not in plan._tasks:
        return []
    seen: set[str] = set()
    q: deque[str] = deque(plan._blocked_by.get(task_id, []))
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for blk in plan._blocked_by.get(cur, []):
            if blk not in seen:
                q.append(blk)
    return sorted(seen)


def ready_tasks(plan: FactoryPlan, completed: list[str]) -> list[str]:
    done = set(completed)
    ready: list[str] = []
    for tid in sorted(plan._tasks):
        if tid in done:
            continue
        needs = blocked_by(plan, tid)
        if all(dep in done for dep in needs):
            ready.append(tid)
    return ready


def wave_count(plan: FactoryPlan) -> int:
    done: list[str] = []
    waves = 0
    while len(done) < len(plan._tasks):
        nxt = ready_tasks(plan, done)
        if not nxt:
            break
        waves += 1
        done.extend(nxt)
    return waves
