"""PostGraphDB/postgraph#1081 — adjacency-list pages split from property pages."""

from __future__ import annotations

from collections import deque
from math import sqrt


class GraphStorage:
    def __init__(self) -> None:
        self.adj: dict[str, list[tuple[str, str]]] = {}
        self.vertex_props: dict[str, dict[str, object]] = {}
        self.edge_props: dict[str, dict[str, object]] = {}
        self.vectors: dict[str, tuple[float, ...]] = {}


def make_storage() -> GraphStorage:
    return GraphStorage()


def add_vertex(
    storage: GraphStorage,
    vid: str,
    props: dict[str, object],
    vector: tuple[float, ...],
) -> None:
    storage.vertex_props[vid] = dict(props)
    storage.vectors[vid] = tuple(vector)
    storage.adj.setdefault(vid, [])


def add_edge(
    storage: GraphStorage,
    eid: str,
    src: str,
    dst: str,
    props: dict[str, object],
) -> None:
    if src not in storage.adj or dst not in storage.adj:
        raise KeyError("unknown vertex")
    storage.edge_props[eid] = dict(props)
    storage.adj[src].append((dst, eid))


def adjacency_neighbors(storage: GraphStorage, vid: str) -> list[str]:
    if vid not in storage.adj:
        return []
    return sorted({nbr for nbr, _ in storage.adj[vid]})


def heap_scan_neighbors(storage: GraphStorage, vid: str) -> list[str]:
    found: set[str] = set()
    for start, entries in storage.adj.items():
        if start != vid:
            continue
        for nbr, _ in entries:
            found.add(nbr)
    return sorted(found)


def bfs_reachable(storage: GraphStorage, start: str, max_hops: int) -> list[str]:
    if start not in storage.adj:
        return []
    seen: set[str] = {start}
    frontier: deque[tuple[str, int]] = deque([(start, 0)])
    while frontier:
        node, depth = frontier.popleft()
        if depth >= max_hops:
            continue
        for nbr, _ in sorted(storage.adj.get(node, []), key=lambda item: item[0]):
            if nbr not in seen:
                seen.add(nbr)
                frontier.append((nbr, depth + 1))
    seen.discard(start)
    return sorted(seen)


def bfs_edge_property_refs(
    storage: GraphStorage, start: str, max_hops: int
) -> list[str]:
    if start not in storage.adj:
        return []
    seen_v: set[str] = {start}
    seen_e: set[str] = set()
    frontier: deque[tuple[str, int]] = deque([(start, 0)])
    while frontier:
        node, depth = frontier.popleft()
        if depth >= max_hops:
            continue
        for nbr, eid in sorted(storage.adj.get(node, []), key=lambda item: item[0]):
            seen_e.add(eid)
            if nbr not in seen_v:
                seen_v.add(nbr)
                frontier.append((nbr, depth + 1))
    return sorted(seen_e)


def neighbors_matching_edge_prop(
    storage: GraphStorage, vid: str, key: str, value: object
) -> list[str]:
    if vid not in storage.adj:
        return []
    out: list[str] = []
    for nbr, eid in storage.adj[vid]:
        props = storage.edge_props.get(eid, {})
        if props.get(key) == value:
            out.append(nbr)
    return sorted(out)


def vector_knn(
    storage: GraphStorage, query: tuple[float, ...], k: int
) -> list[str]:
    ranked: list[tuple[float, str]] = []
    for vid, vec in storage.vectors.items():
        dist = sqrt(sum((query[i] - vec[i]) ** 2 for i in range(len(query))))
        ranked.append((dist, vid))
    ranked.sort()
    return [vid for _, vid in ranked[:k]]


def storage_views_agree(storage: GraphStorage, vid: str) -> bool:
    return adjacency_neighbors(storage, vid) == heap_scan_neighbors(storage, vid)
