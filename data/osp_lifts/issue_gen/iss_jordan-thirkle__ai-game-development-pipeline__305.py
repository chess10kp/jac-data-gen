"""jordan-thirkle/ai-game-development-pipeline#305 — BYJTT-LAB-001 integrated Three.js alpha browser perf pipeline DAG."""

from __future__ import annotations

from typing import Dict, List, Set


class PipelineGraph:
    """Mutable perf-measurement pipeline keyed by stage id."""

    def __init__(self) -> None:
        self._nodes: Set[str] = set()
        self._deps: Dict[str, List[str]] = {}
        self._rev: Dict[str, List[str]] = {}

    def add_stage(self, stage_id: str) -> None:
        if stage_id in self._nodes:
            return
        self._nodes.add(stage_id)
        self._deps.setdefault(stage_id, [])
        self._rev.setdefault(stage_id, [])

    def add_dependency(self, stage: str, depends_on: str) -> None:
        if stage not in self._nodes or depends_on not in self._nodes:
            raise KeyError("unknown pipeline stage id")
        self._deps[stage].append(depends_on)
        self._rev[depends_on].append(stage)

    def find_cycle(self) -> List[str]:
        WHITE, GRAY, BLACK = 0, 1, 2
        color: Dict[str, int] = {n: WHITE for n in self._nodes}
        stack: List[str] = []

        def dfs(u: str) -> List[str]:
            color[u] = GRAY
            stack.append(u)
            for v in self._deps.get(u, []):
                if color[v] == WHITE:
                    found = dfs(v)
                    if found:
                        return found
                elif color[v] == GRAY:
                    if v in stack:
                        i = stack.index(v)
                        return stack[i:] + [v]
                    return [v, u, v]
            stack.pop()
            color[u] = BLACK
            return []

        for n in sorted(self._nodes):
            if color[n] == WHITE:
                cyc = dfs(n)
                if cyc:
                    return cyc
        return []

    def downstream(self, stage: str) -> List[str]:
        if stage not in self._nodes:
            return []
        claimed: Set[str] = set()
        out: List[str] = []
        stack: List[str] = list(self._rev.get(stage, []))
        while stack:
            u = stack.pop()
            if u in claimed:
                continue
            claimed.add(u)
            out.append(u)
            for v in self._rev.get(u, []):
                if v not in claimed:
                    stack.append(v)
        return sorted(out)
