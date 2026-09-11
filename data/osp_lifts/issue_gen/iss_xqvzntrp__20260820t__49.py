"""xqvzntrp/20260820t#49 — Execution orchestration over verified model closure."""

from __future__ import annotations

from collections import deque


class CycleError(Exception):
    pass


class ExecStore:
    # Model dependency edges for execution ordering.
    def __init__(self) -> None:
        self._models: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._outputs: dict[str, str] = {}


def load_execution(
    model_names: list[str],
    depends_edges: list[tuple[str, str]],
    outputs: dict[str, str] | None = None,
) -> ExecStore:
    store = ExecStore()
    for name in model_names:
        store._models.add(name)
        store._depends.setdefault(name, [])
        store._outputs[name] = name
    for upstream, downstream in depends_edges:
        if upstream in store._models and downstream in store._models:
            store._depends.setdefault(downstream, []).append(upstream)
    if outputs:
        for k, v in outputs.items():
            if k in store._models:
                store._outputs[k] = v
    return store


def execution_order(store: ExecStore) -> list[str]:
    indegree: dict[str, int] = {m: 0 for m in store._models}
    for m, deps in store._depends.items():
        indegree[m] = len(deps)
    order: list[str] = []
    ready = {m for m, d in indegree.items() if d == 0}
    while ready:
        nxt = min(ready)
        ready.remove(nxt)
        order.append(nxt)
        for m, deps in store._depends.items():
            if nxt in deps:
                indegree[m] -= 1
                if indegree[m] == 0:
                    ready.add(m)
    if len(order) != len(store._models):
        raise CycleError("cycle in execution graph")
    return order


def upstream_closure(store: ExecStore, model: str) -> list[str]:
    if model not in store._models:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([model])
    while queue:
        cur = queue.popleft()
        for dep in store._depends.get(cur, []):
            if dep not in seen:
                seen.add(dep)
                queue.append(dep)
    return sorted(seen)


def bind_output(store: ExecStore, model: str) -> str:
    if model not in store._models:
        return ""
    return store._outputs.get(model, model)
