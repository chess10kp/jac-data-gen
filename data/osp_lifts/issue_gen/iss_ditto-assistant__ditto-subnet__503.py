"""ditto-assistant/ditto-subnet#503 — Recursive compositional query dependency graph."""

from __future__ import annotations

from collections import deque


class QueryGraph:
    # Adjacency for compositional query steps (joins, filters, aggregations).
    def __init__(self) -> None:
        self._steps: set[str] = set()
        self._depends: dict[str, list[str]] = {}


def load_query_graph(
    steps: list[str],
    depends_edges: list[tuple[str, str]],
) -> QueryGraph:
    g = QueryGraph()
    for s in steps:
        g._steps.add(s)
        g._depends.setdefault(s, [])
    for upstream, downstream in depends_edges:
        if upstream in g._steps and downstream in g._steps:
            g._depends.setdefault(downstream, []).append(upstream)
            g._depends.setdefault(upstream, g._depends.get(upstream, []))
    return g


def evaluation_order(store: QueryGraph, root: str) -> list[str]:
    if root not in store._steps:
        return []
    depth: dict[str, int] = {root: 0}
    order: list[tuple[int, str]] = [(0, root)]
    queue: deque[str] = deque([root])
    seen: set[str] = {root}
    while queue:
        cur = queue.popleft()
        for dep in store._depends.get(cur, []):
            nd = depth[cur] + 1
            if dep not in seen:
                seen.add(dep)
                depth[dep] = nd
                order.append((nd, dep))
                queue.append(dep)
            elif nd > depth.get(dep, 0):
                depth[dep] = nd
                order.append((nd, dep))
    order.sort(key=lambda t: (t[0], t[1]))
    return [name for _, name in order]


def reachable_steps(store: QueryGraph, root: str) -> list[str]:
    if root not in store._steps:
        return []
    seen: set[str] = {root}
    stack = [root]
    while stack:
        cur = stack.pop()
        for dep in store._depends.get(cur, []):
            if dep not in seen:
                seen.add(dep)
                stack.append(dep)
    return sorted(seen)
