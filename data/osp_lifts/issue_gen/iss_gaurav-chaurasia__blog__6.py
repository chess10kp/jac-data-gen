"""gaurav-chaurasia/blog#6 — Graph BFS reachability and path queries."""

from __future__ import annotations

from collections import deque


class GraphStore:
    # Undirected adjacency list for graph traversal exercises.
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._adj: dict[str, list[str]] = {}


def load_graph(
    node_ids: list[str],
    edges: list[tuple[str, str]],
) -> GraphStore:
    g = GraphStore()
    for nid in node_ids:
        g._nodes.add(nid)
        g._adj.setdefault(nid, [])
    for a, b in edges:
        if a in g._nodes and b in g._nodes:
            if b not in g._adj[a]:
                g._adj[a].append(b)
            if a not in g._adj[b]:
                g._adj[b].append(a)
    return g


def bfs_reachable(store: GraphStore, start: str) -> list[str]:
    if start not in store._nodes:
        return []
    seen: set[str] = {start}
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        for nxt in store._adj.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def has_path(store: GraphStore, src: str, dst: str) -> bool:
    if src not in store._nodes or dst not in store._nodes:
        return False
    if src == dst:
        return True
    seen: set[str] = {src}
    queue: deque[str] = deque([src])
    while queue:
        cur = queue.popleft()
        for nxt in store._adj.get(cur, []):
            if nxt == dst:
                return True
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return False


def component_size(store: GraphStore, start: str) -> int:
    return len(bfs_reachable(store, start))
