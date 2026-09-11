"""gastownhall/gascity#5383 — batched Reaper query layers over workflow DAG."""
from __future__ import annotations

from collections import deque
from typing import Dict, List, Set


class CycleError(ValueError):
    pass


class ReaperGraph:
    def __init__(self) -> None:
        self._nodes: Set[str] = set()
        self._deps: Dict[str, List[str]] = {}
        self._rev: Dict[str, List[str]] = {}

    def add_step(self, step_id: str) -> None:
        self._nodes.add(step_id)
        self._deps.setdefault(step_id, [])
        self._rev.setdefault(step_id, [])

    def add_depends(self, step_id: str, depends_on: str) -> None:
        if step_id not in self._nodes or depends_on not in self._nodes:
            raise KeyError("unknown step")
        self._deps[step_id].append(depends_on)
        self._rev[depends_on].append(step_id)

    def query_layers(self) -> List[List[str]]:
        indeg = {n: len(self._deps[n]) for n in self._nodes}
        layers: List[List[str]] = []
        frontier = sorted(n for n, d in indeg.items() if d == 0)
        seen: Set[str] = set()
        while frontier:
            layer = sorted(frontier)
            layers.append(layer)
            nxt: List[str] = []
            for u in layer:
                seen.add(u)
                for v in sorted(self._rev.get(u, [])):
                    indeg[v] -= 1
                    if indeg[v] == 0 and v not in seen:
                        nxt.append(v)
            frontier = nxt
        if len(seen) != len(self._nodes):
            raise CycleError("cycle blocks layering")
        return layers

    def reachable_downstream(self, start: str) -> List[str]:
        if start not in self._nodes:
            return []
        seen: Set[str] = set()
        q: deque[str] = deque([start])
        out: List[str] = []
        while q:
            u = q.popleft()
            if u in seen:
                continue
            seen.add(u)
            out.append(u)
            for v in self._rev.get(u, []):
                if v not in seen:
                    q.append(v)
        return sorted(out)


def build_reaper() -> ReaperGraph:
    return ReaperGraph()
