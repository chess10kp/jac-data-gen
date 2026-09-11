"""Evokoa/pgGraph#23 — shortest path with optional edge_types filter."""

from __future__ import annotations

from collections import deque


class GraphStore:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._edges: dict[str, list[tuple[str, str]]] = {}


def load_graph(
    nodes: list[str],
    edges: list[tuple[str, str, str]],
) -> GraphStore:
    store = GraphStore()
    for nid in nodes:
        store._nodes.add(nid)
        store._edges.setdefault(nid, [])
    for src, dst, etype in edges:
        if src in store._nodes and dst in store._nodes:
            store._edges.setdefault(src, []).append((dst, etype))
    return store


def _allowed(etype: str, edge_types: list[str] | None) -> bool:
    if edge_types is None:
        return True
    return etype in edge_types


def shortest_path(
    store: GraphStore,
    source: str,
    target: str,
    edge_types: list[str] | None = None,
    max_depth: int = 20,
) -> list[str] | None:
    if source not in store._nodes or target not in store._nodes:
        return None
    if source == target:
        return [source]
    q: deque[tuple[str, list[str]]] = deque([(source, [source])])
    seen: set[str] = {source}
    while q:
        cur, path = q.popleft()
        if len(path) > max_depth:
            continue
        for nxt, etype in store._edges.get(cur, []):
            if not _allowed(etype, edge_types):
                continue
            if nxt in seen:
                continue
            npath = path + [nxt]
            if nxt == target:
                return npath
            seen.add(nxt)
            q.append((nxt, npath))
    return None


def reachable_within(
    store: GraphStore,
    source: str,
    max_depth: int,
    edge_types: list[str] | None = None,
) -> list[str]:
    if source not in store._nodes:
        return []
    seen: set[str] = {source}
    reached: list[str] = [source]
    q: deque[tuple[str, int]] = deque([(source, 0)])
    while q:
        cur, depth = q.popleft()
        if depth >= max_depth:
            continue
        for nxt, etype in sorted(store._edges.get(cur, [])):
            if not _allowed(etype, edge_types):
                continue
            if nxt in seen:
                continue
            seen.add(nxt)
            reached.append(nxt)
            q.append((nxt, depth + 1))
    return sorted(reached)
