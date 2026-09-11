"""BharatDBPG/BharatDBMS-PG#3005 — recursive view traversal with level tracking."""

from collections import deque


class ViewGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._edges: dict[str, list[str]] = {}


def load_view_graph(nodes: list[str], edges: list[tuple[str, str]]) -> ViewGraph:
    g = ViewGraph()
    for n in nodes:
        g._nodes.add(n)
        g._edges.setdefault(n, [])
    for a, b in edges:
        if a in g._nodes and b in g._nodes:
            g._edges.setdefault(a, []).append(b)
    return g


def reachable_with_levels(store: ViewGraph, start: str) -> dict[str, int]:
    if start not in store._nodes:
        return {}
    levels: dict[str, int] = {start: 0}
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        for nxt in store._edges.get(cur, []):
            nl = levels[cur] + 1
            if nxt not in levels or nl < levels[nxt]:
                levels[nxt] = nl
                queue.append(nxt)
    return dict(levels)
