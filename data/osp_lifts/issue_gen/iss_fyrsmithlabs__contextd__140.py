"""fyrsmithlabs/contextd#140 — Entity graph multi-hop relationship reach."""

from __future__ import annotations

from collections import deque


class EntityGraph:
    def __init__(self) -> None:
        self._entities: set[str] = set()
        self._relates: dict[str, list[str]] = {}


def load_entity_graph(
    entities: list[str],
    relates_edges: list[tuple[str, str]],
) -> EntityGraph:
    g = EntityGraph()
    for eid in entities:
        g._entities.add(eid)
        g._relates.setdefault(eid, [])
    for src, dst in relates_edges:
        if src not in g._entities or dst not in g._entities:
            continue
        g._relates[src].append(dst)
    return g


def reachable_entities(g: EntityGraph, start: str, max_depth: int) -> list[str]:
    if start not in g._entities or max_depth < 0:
        return []
    seen: set[str] = {start}
    q: deque[tuple[str, int]] = deque([(start, 0)])
    while q:
        cur, depth = q.popleft()
        if depth >= max_depth:
            continue
        for nxt in g._relates.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                q.append((nxt, depth + 1))
    return sorted(seen)


def entity_neighbors(g: EntityGraph, entity_id: str) -> list[str]:
    if entity_id not in g._entities:
        return []
    return sorted(g._relates.get(entity_id, []))
