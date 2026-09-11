"""reallaksh19/3D_Converters#443 — FIT calculation dependency DAG.

Engineering workspace calculations declare depends-on edges; stack walk
collects prerequisite calc IDs before a screening gate may run.
"""

from __future__ import annotations


class CalcGraph:
    def __init__(self) -> None:
        self.calcs: set[str] = set()
        self.depends_on: dict[str, list[str]] = {}


def load_calc_graph(
    calcs: list[str],
    depends_edges: list[tuple[str, str]],
) -> CalcGraph:
    g = CalcGraph()
    for cid in calcs:
        g.calcs.add(cid)
        g.depends_on.setdefault(cid, [])
    for prereq, calc in depends_edges:
        if prereq in g.calcs and calc in g.calcs:
            g.depends_on.setdefault(calc, []).append(prereq)
    return g


def _closure(g: CalcGraph, calc_id: str) -> set[str]:
    seen: set[str] = set()
    stack: list[str] = [calc_id]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for dep in sorted(g.depends_on.get(cur, [])):
            stack.append(dep)
    return seen


def prerequisites(g: CalcGraph, calc_id: str) -> list[str]:
    if calc_id not in g.calcs:
        return []
    return sorted(_closure(g, calc_id))


def ready_calcs(g: CalcGraph, completed: list[str]) -> list[str]:
    done = set(completed)
    ready: list[str] = []
    for cid in sorted(g.calcs):
        if cid in done:
            continue
        needs = [p for p in prerequisites(g, cid) if p != cid]
        if all(p in done for p in needs):
            ready.append(cid)
    return ready
