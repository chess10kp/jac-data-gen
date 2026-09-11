"""Beta hardening DAG execution order. Source: AxiomaSystems/Chef#80."""

from __future__ import annotations

from collections import deque
from typing import DefaultDict


def _build_graph(
    tasks: list[str], depends: list[tuple[str, str]]
) -> tuple[dict[str, list[str]], dict[str, int]]:
    adj: DefaultDict[str, list[str]] = DefaultDict(list)
    indeg: dict[str, int] = {t: 0 for t in tasks}
    for a, b in depends:
        adj[a].append(b)
        indeg[b] = indeg.get(b, 0) + 1
        indeg.setdefault(a, 0)
    return dict(adj), indeg


def execution_order(tasks: list[str], depends: list[tuple[str, str]]) -> list[str]:
    adj, indeg = _build_graph(tasks, depends)
    q: deque[str] = deque(sorted(t for t in tasks if indeg.get(t, 0) == 0))
    order: list[str] = []
    while q:
        node = q.popleft()
        order.append(node)
        for nxt in sorted(adj.get(node, [])):
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                q.append(nxt)
    return order


def hardening_ready(task: str, completed: set[str], depends: list[tuple[str, str]]) -> bool:
    for a, b in depends:
        if b == task and a not in completed:
            return False
    return True


def tasks_by_owner(owners: dict[str, str]) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for task, owner in sorted(owners.items()):
        out.setdefault(owner, []).append(task)
    for owner in out:
        out[owner] = sorted(out[owner])
    return out
