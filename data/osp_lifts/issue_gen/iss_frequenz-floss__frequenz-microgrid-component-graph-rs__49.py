"""frequenz-floss/frequenz-microgrid-component-graph-rs#49 — Prune topmost meter candidates."""

from __future__ import annotations

from collections import deque


class MeterGraph:
    def __init__(self) -> None:
        self._meters: set[str] = set()
        self._feeds: dict[str, list[str]] = {}


def load_meter_graph(meters: list[str], feeds: list[tuple[str, str]]) -> MeterGraph:
    g = MeterGraph()
    for mid in meters:
        g._meters.add(mid)
        g._feeds.setdefault(mid, [])
    for src, dst in feeds:
        if src in g._meters and dst in g._meters:
            g._feeds.setdefault(src, []).append(dst)
    return g


def reaches_any(graph: MeterGraph, start: str, targets: set[str]) -> bool:
    if start not in graph._meters:
        return False
    visited: set[str] = set()
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        if cur in visited:
            continue
        visited.add(cur)
        if cur in targets and cur != start:
            return True
        for nxt in graph._feeds.get(cur, []):
            if nxt not in visited:
                queue.append(nxt)
    return False


def prune_topmost_candidates(graph: MeterGraph, candidates: list[str]) -> list[str]:
    ordered = sorted(candidates)
    keep: list[str] = []
    for mid in ordered:
        dominated = any(
            other != mid and reaches_any(graph, other, {mid})
            for other in ordered
        )
        if not dominated:
            keep.append(mid)
    return keep
