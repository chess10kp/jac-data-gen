"""1btc-news/news-client#33 — Agent workflow DAG for quantum beat deliverables."""

from __future__ import annotations

from collections import deque


class WorkflowStore:
    # Parent/child role dependencies in agent workflow.
    def __init__(self) -> None:
        self._roles: set[str] = set()
        self._requires: dict[str, list[str]] = {}
        self._status: dict[str, str] = {}


def load_workflow(
    role_names: list[str],
    require_edges: list[tuple[str, str]],
    status: dict[str, str] | None = None,
) -> WorkflowStore:
    store = WorkflowStore()
    for role in role_names:
        store._roles.add(role)
        store._requires.setdefault(role, [])
        store._status[role] = "pending"
    for upstream, downstream in require_edges:
        if upstream in store._roles and downstream in store._roles:
            store._requires.setdefault(downstream, []).append(upstream)
    if status:
        for k, v in status.items():
            if k in store._roles:
                store._status[k] = v
    return store


def ready_roles(store: WorkflowStore) -> list[str]:
    out: list[str] = []
    for role in sorted(store._roles):
        if store._status.get(role) != "pending":
            continue
        deps = store._requires.get(role, [])
        if all(store._status.get(d) == "done" for d in deps):
            out.append(role)
    return out


def prerequisite_chain(store: WorkflowStore, role: str) -> list[str]:
    if role not in store._roles:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([role])
    while queue:
        cur = queue.popleft()
        for dep in store._requires.get(cur, []):
            if dep not in seen:
                seen.add(dep)
                queue.append(dep)
    return sorted(seen)


def mark_done(store: WorkflowStore, role: str) -> list[str]:
    if role not in store._roles:
        return []
    store._status[role] = "done"
    return ready_roles(store)
