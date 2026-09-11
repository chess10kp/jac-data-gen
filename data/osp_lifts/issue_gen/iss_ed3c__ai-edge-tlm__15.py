"""ed3c/ai-edge-tlm#15 — Foundation DAG validation and reachability."""

from __future__ import annotations

from collections import deque


class DagStore:
    # Adjacency dict for true-dependency edges between foundation tasks.
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._deps: dict[str, list[str]] = {}


def load_dag(
    node_ids: list[str],
    depends_edges: list[tuple[str, str]],
) -> DagStore:
    dag = DagStore()
    for nid in node_ids:
        dag._nodes.add(nid)
        dag._deps.setdefault(nid, [])
    for upstream, downstream in depends_edges:
        if upstream in dag._nodes and downstream in dag._nodes:
            dag._deps.setdefault(downstream, []).append(upstream)
            dag._deps.setdefault(upstream, dag._deps.get(upstream, []))
    return dag


def validate_dag(store: DagStore) -> list[tuple[str, str]]:
    errors: list[tuple[str, str]] = []
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> None:
        visited.add(node)
        stack.add(node)
        for dep in store._deps.get(node, []):
            if dep in stack:
                errors.append((dep, node))
            elif dep not in visited:
                dfs(dep)
        stack.remove(node)

    for node in sorted(store._nodes):
        if node not in visited:
            dfs(node)
    return sorted(errors)


def reachable_from(store: DagStore, start: str) -> list[str]:
    if start not in store._nodes:
        return []
    rev: dict[str, list[str]] = {n: [] for n in store._nodes}
    for downstream, ups in store._deps.items():
        for up in ups:
            rev[up].append(downstream)
    seen: set[str] = {start}
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        for nxt in rev.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def has_cycle(store: DagStore) -> bool:
    return len(validate_dag(store)) > 0
