"""Saanvi51/bigstardust-workspace#332 — Graph connected components via BFS."""

from __future__ import annotations

from collections import deque


class StudyGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._adj: dict[str, list[str]] = {}


def load_study_graph(
    nodes: list[str],
    edges: list[tuple[str, str]],
) -> StudyGraph:
    g = StudyGraph()
    for nid in nodes:
        g._nodes.add(nid)
        g._adj.setdefault(nid, [])
    for a, b in edges:
        if a in g._nodes and b in g._nodes:
            g._adj.setdefault(a, []).append(b)
            g._adj.setdefault(b, []).append(a)
    return g


def connected_components(graph: StudyGraph) -> list[list[str]]:
    seen: set[str] = set()
    comps: list[list[str]] = []
    for start in sorted(graph._nodes):
        if start in seen:
            continue
        comp: list[str] = []
        queue: deque[str] = deque([start])
        while queue:
            cur = queue.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            comp.append(cur)
            for nxt in graph._adj.get(cur, []):
                if nxt not in seen:
                    queue.append(nxt)
        comps.append(sorted(comp))
    return sorted(comps)


def component_count(graph: StudyGraph) -> int:
    return len(connected_components(graph))
