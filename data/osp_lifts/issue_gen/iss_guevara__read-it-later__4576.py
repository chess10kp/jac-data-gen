"""guevara/read-it-later#4576 — adjacency reach and cycle detection."""

from __future__ import annotations

from collections import deque


class GraphStore:
    def __init__(self) -> None:
        self.adj: dict[str, list[str]] = {}


def load_graph(nodes: list[str], edges: list[tuple[str, str]]) -> GraphStore:
    g = GraphStore()
    for n in nodes:
        g.adj.setdefault(n, [])
    for a, b in edges:
        if a in g.adj and b in g.adj:
            g.adj[a].append(b)
    return g


def reachable_from(g: GraphStore, start: str) -> list[str]:
    if start not in g.adj:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([start])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in sorted(g.adj.get(cur, [])):
            if nxt not in seen:
                q.append(nxt)
    return sorted(seen)


def cycle_nodes(g: GraphStore) -> list[str]:
    WHITE, GRAY, BLACK = 0, 1, 2
    color: dict[str, int] = {}
    found: set[str] = set()

    def dfs(n: str) -> None:
        color[n] = GRAY
        for nxt in g.adj.get(n, []):
            st = color.get(nxt, WHITE)
            if st == GRAY:
                found.add(nxt)
            elif st == WHITE:
                dfs(nxt)
        color[n] = BLACK

    for n in sorted(g.adj):
        if color.get(n, WHITE) == WHITE:
            dfs(n)
    return sorted(found)
