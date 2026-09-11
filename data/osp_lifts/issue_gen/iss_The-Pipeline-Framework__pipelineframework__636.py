"""The-Pipeline-Framework/pipelineframework#636 — recursive agent pipeline composition."""

from __future__ import annotations

from collections import deque


class PipelineStore:
    # Step registry plus spawn/depends adjacency for one-turn agent loops.
    def __init__(self) -> None:
        self._steps: dict[str, str | None] = {}
        self._spawn_of: dict[str, list[str]] = {}
        self._depends: dict[str, list[str]] = {}
        self._turn_budget: int = 0


def load_pipeline(
    steps: list[tuple[str, str | None]],
    spawn_edges: list[tuple[str, str]],
    depends_edges: list[tuple[str, str]],
    turn_budget: int,
) -> PipelineStore:
    store = PipelineStore()
    store._turn_budget = max(0, turn_budget)
    for name, parent in steps:
        store._steps[name] = parent
        store._spawn_of.setdefault(name, [])
        if parent is not None:
            store._spawn_of.setdefault(parent, []).append(name)
    for caller, callee in spawn_edges:
        if caller in store._steps and callee in store._steps:
            if callee not in store._spawn_of.setdefault(caller, []):
                store._spawn_of[caller].append(callee)
    for upstream, downstream in depends_edges:
        if upstream in store._steps and downstream in store._steps:
            store._depends.setdefault(downstream, []).append(upstream)
    return store


def ancestor_chain(store: PipelineStore, step: str) -> list[str]:
    if step not in store._steps:
        return []
    chain: list[str] = []
    cur: str | None = step
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store._steps.get(cur)
    return list(reversed(chain))


def reachable_via_spawn(store: PipelineStore, root: str) -> list[str]:
    if root not in store._steps:
        return []
    seen: set[str] = {root}
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for nxt in store._spawn_of.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def ready_after_deps(store: PipelineStore, completed: list[str]) -> list[str]:
    done = set(completed)
    out: list[str] = []
    for step in sorted(store._steps):
        deps = store._depends.get(step, [])
        if all(d in done for d in deps) and step not in done:
            out.append(step)
    return out


def bounded_turns(store: PipelineStore, start: str) -> list[str]:
    if start not in store._steps:
        return []
    path: list[str] = [start]
    cur = start
    for _ in range(store._turn_budget):
        nxt_list = store._spawn_of.get(cur, [])
        if not nxt_list:
            break
        cur = sorted(nxt_list)[0]
        path.append(cur)
    return path
