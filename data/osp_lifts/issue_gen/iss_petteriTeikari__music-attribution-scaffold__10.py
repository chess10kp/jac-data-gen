"""petteriTeikari/music-attribution-scaffold#10 — GraphStore multi-hop neighbor walk.

Hand-rolled adjacency dict + queue BFS replacing iterative edge-table lookups
for 1-hop, 2-hop, and 3-hop entity traversals before Apache AGE Cypher lift.
"""

from __future__ import annotations

from collections import deque


class EdgeGraph:
    def __init__(self) -> None:
        self._entities: set[str] = set()
        self._adj: dict[str, list[str]] = {}


def load_graph(
    entities: list[str],
    edges: list[tuple[str, str]],
) -> EdgeGraph:
    g = EdgeGraph()
    for eid in entities:
        g._entities.add(eid)
        g._adj.setdefault(eid, [])
    for src, dst in edges:
        if src in g._entities and dst in g._entities:
            g._adj.setdefault(src, []).append(dst)
    return g


def neighbors_at_hop(g: EdgeGraph, entity_id: str, hops: int) -> list[str]:
    if entity_id not in g._entities or hops < 1:
        return []
    frontier: set[str] = {entity_id}
    for _ in range(hops):
        nxt: set[str] = set()
        for cur in frontier:
            for nb in g._adj.get(cur, []):
                nxt.add(nb)
        frontier = nxt
        if not frontier:
            break
    return sorted(frontier)


def all_reachable(g: EdgeGraph, entity_id: str, max_hops: int = 3) -> list[str]:
    if entity_id not in g._entities:
        return []
    seen: set[str] = {entity_id}
    q: deque[tuple[str, int]] = deque([(entity_id, 0)])
    while q:
        cur, depth = q.popleft()
        if depth >= max_hops:
            continue
        for nb in g._adj.get(cur, []):
            if nb not in seen:
                seen.add(nb)
                q.append((nb, depth + 1))
    seen.discard(entity_id)
    return sorted(seen)


def has_cycle(g: EdgeGraph) -> bool:
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> bool:
        visited.add(node)
        stack.add(node)
        for nb in g._adj.get(node, []):
            if nb not in visited:
                if dfs(nb):
                    return True
            elif nb in stack:
                return True
        stack.discard(node)
        return False

    for eid in sorted(g._entities):
        if eid not in visited and dfs(eid):
            return True
    return False
