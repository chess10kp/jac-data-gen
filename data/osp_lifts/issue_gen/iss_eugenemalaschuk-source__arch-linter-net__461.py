"""eugenemalaschuk-source/arch-linter-net#461 — Project lineage and phase reachability."""

from __future__ import annotations

from collections import deque


class AnalysisGraph:
    def __init__(self) -> None:
        self._projects: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._phase_deps: dict[str, list[str]] = {}


def load_analysis_graph(
    projects: list[str],
    parent_edges: list[tuple[str, str | None]],
    phase_edges: list[tuple[str, str]],
) -> AnalysisGraph:
    g = AnalysisGraph()
    for pid in projects:
        g._projects.add(pid)
        g._parent.setdefault(pid, None)
        g._phase_deps.setdefault(pid, [])
    for pid, par in parent_edges:
        if pid in g._projects:
            g._parent[pid] = par
    for phase, deps in phase_edges:
        if isinstance(deps, str):
            deps = [deps]
        for dep in deps:
            g._phase_deps.setdefault(phase, []).append(dep)
    return g


def _project_ancestors(g: AnalysisGraph, pid: str, acc: list[str]) -> None:
    par = g._parent.get(pid)
    if par is None or par not in g._projects:
        return
    if par in acc:
        return
    acc.append(par)
    _project_ancestors(g, par, acc)


def project_ancestors(g: AnalysisGraph, project_id: str) -> list[str]:
    if project_id not in g._projects:
        return []
    out: list[str] = []
    _project_ancestors(g, project_id, out)
    return out


def phases_reachable_from(g: AnalysisGraph, seed_phases: list[str]) -> list[str]:
    seen: set[str] = set()
    q: deque[str] = deque(seed_phases)
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for dep in g._phase_deps.get(cur, []):
            if dep not in seen:
                q.append(dep)
    return sorted(seen)
