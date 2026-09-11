"""dsyme/tokio#10 — Runtime task spawn dependency reachability."""

from __future__ import annotations

from collections import deque


class TaskGraph:
    def __init__(self) -> None:
        self._tasks: set[str] = set()
        self._spawns: dict[str, list[str]] = {}


def load_task_graph(
    tasks: list[str],
    spawn_edges: list[tuple[str, str]],
) -> TaskGraph:
    g = TaskGraph()
    for t in tasks:
        g._tasks.add(t)
        g._spawns.setdefault(t, [])
    for parent, child in spawn_edges:
        if parent in g._tasks and child in g._tasks:
            g._spawns.setdefault(parent, []).append(child)
    return g


def reachable_tasks(graph: TaskGraph, root: str) -> list[str]:
    if root not in graph._tasks:
        return []
    seen: set[str] = {root}
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for nxt in graph._spawns.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def spawn_depth_within(graph: TaskGraph, root: str, limit: int) -> bool:
    if root not in graph._tasks:
        return False
    depth: dict[str, int] = {root: 0}
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for nxt in graph._spawns.get(cur, []):
            nd = depth[cur] + 1
            if nd > limit:
                return False
            if nxt not in depth or nd > depth[nxt]:
                depth[nxt] = nd
                queue.append(nxt)
    return True


def orphan_tasks(graph: TaskGraph, roots: list[str]) -> list[str]:
    reachable: set[str] = set()
    for r in roots:
        reachable.update(reachable_tasks(graph, r))
    return sorted(t for t in graph._tasks if t not in reachable)
