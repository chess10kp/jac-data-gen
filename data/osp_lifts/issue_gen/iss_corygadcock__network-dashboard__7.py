"""corygadcock/network-dashboard#7 — BFS trace to gateway with break reason."""

from __future__ import annotations

from collections import deque


class TopoStore:
    def __init__(self) -> None:
        self.adj: dict[str, list[str]] = {}


def load_topology(
    nodes: list[str],
    links: list[tuple[str, str]],
) -> TopoStore:
    t = TopoStore()
    for n in nodes:
        t.adj.setdefault(n, [])
    for src, dst in links:
        if src in t.adj and dst in t.adj:
            t.adj[src].append(dst)
    return t


def trace_to_gateway(
    store: TopoStore,
    start: str,
    gateway: str,
) -> tuple[list[str], str | None]:
    if start not in store.adj:
        return ([], "unknown_start")
    parent: dict[str, str | None] = {start: None}
    q: deque[str] = deque([start])
    while q:
        cur = q.popleft()
        if cur == gateway:
            path: list[str] = []
            node: str | None = cur
            while node is not None:
                path.append(node)
                node = parent[node]
            return (list(reversed(path)), None)
        for nxt in sorted(store.adj.get(cur, [])):
            if nxt not in parent:
                parent[nxt] = cur
                q.append(nxt)
    deepest = max(parent.keys(), key=lambda n: _depth(parent, n, start))
    partial = _reconstruct(parent, deepest)
    return (partial, "missing_documentation")


def _depth(parent: dict[str, str | None], node: str, start: str) -> int:
    d = 0
    cur: str | None = node
    while cur is not None and cur != start:
        d += 1
        cur = parent.get(cur)
    return d


def _reconstruct(parent: dict[str, str | None], end: str) -> list[str]:
    path: list[str] = []
    cur: str | None = end
    while cur is not None:
        path.append(cur)
        cur = parent[cur]
    return list(reversed(path))
