"""FrankieJay52/Brinesearch#97 — road junction connectivity via BFS."""

from __future__ import annotations

from collections import deque


class RoadGraph:
    def __init__(self) -> None:
        self._roads: set[str] = set()
        self._junctions: set[str] = set()
        self._road_at: dict[str, list[str]] = {}
        self._connects: dict[str, list[str]] = {}


def load_road_graph(
    roads: list[str],
    junctions: list[str],
    road_junction_edges: list[tuple[str, str]],
    junction_link_edges: list[tuple[str, str]] | None = None,
) -> RoadGraph:
    g = RoadGraph()
    for rid in roads:
        g._roads.add(rid)
        g._road_at.setdefault(rid, [])
    for jid in junctions:
        g._junctions.add(jid)
        g._connects.setdefault(jid, [])
    for road, junction in road_junction_edges:
        if road in g._roads and junction in g._junctions:
            g._road_at.setdefault(road, []).append(junction)
            g._connects.setdefault(junction, []).append(road)
    if junction_link_edges:
        for j1, j2 in junction_link_edges:
            if j1 in g._junctions and j2 in g._junctions:
                g._connects.setdefault(j1, []).append(j2)
                g._connects.setdefault(j2, []).append(j1)
    return g


def connected_roads(store: RoadGraph, road_id: str) -> list[str]:
    if road_id not in store._roads:
        return []
    seen_roads: set[str] = {road_id}
    seen_junctions: set[str] = set()
    queue: deque[str] = deque(store._road_at.get(road_id, []))
    while queue:
        cur = queue.popleft()
        if cur in store._junctions:
            if cur in seen_junctions:
                continue
            seen_junctions.add(cur)
            for nxt in store._connects.get(cur, []):
                if nxt in store._roads and nxt not in seen_roads:
                    seen_roads.add(nxt)
                queue.append(nxt)
        elif cur in store._roads:
            for j in store._road_at.get(cur, []):
                if j not in seen_junctions:
                    queue.append(j)
    seen_roads.discard(road_id)
    return sorted(seen_roads)


def junction_reach(store: RoadGraph, junction_id: str) -> list[str]:
    if junction_id not in store._junctions:
        return []
    seen_junctions: set[str] = {junction_id}
    seen_roads: set[str] = set()
    queue: deque[str] = deque(store._connects.get(junction_id, []))
    while queue:
        cur = queue.popleft()
        if cur in store._junctions:
            if cur in seen_junctions:
                continue
            seen_junctions.add(cur)
            queue.extend(store._connects.get(cur, []))
        elif cur in store._roads:
            if cur in seen_roads:
                continue
            seen_roads.add(cur)
            for j in store._road_at.get(cur, []):
                if j not in seen_junctions:
                    queue.append(j)
    out: list[str] = []
    for j in seen_junctions:
        if j != junction_id:
            out.append(j)
    out.extend(sorted(seen_roads))
    return sorted(out)


def road_component_size(store: RoadGraph, road_id: str) -> int:
    if road_id not in store._roads:
        return 0
    return 1 + len(connected_roads(store, road_id))
