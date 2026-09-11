"""ZanattaMichael/Dsc.PipelineRunner#23 — Kahn topological sort with cycle error."""

from __future__ import annotations

from collections import deque


class ResourceGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._deps: dict[str, set[str]] = {}
        self._dependents: dict[str, set[str]] = {}


def load_resources(
    names: list[str],
    depends: dict[str, list[str]],
) -> ResourceGraph:
    g = ResourceGraph()
    for name in names:
        g._nodes.add(name)
        g._deps.setdefault(name, set())
        g._dependents.setdefault(name, set())
    for name, blockers in depends.items():
        if name not in g._nodes:
            continue
        for blocker in blockers:
            if blocker not in g._nodes:
                raise KeyError(f"missing resource: {blocker}")
            g._deps[name].add(blocker)
            g._dependents[blocker].add(name)
    return g


def sort_depends_on(g: ResourceGraph) -> list[str]:
    indeg: dict[str, int] = {n: len(g._deps[n]) for n in g._nodes}
    q: deque[str] = deque(sorted(n for n, d in indeg.items() if d == 0))
    out: list[str] = []
    while q:
        cur = q.popleft()
        out.append(cur)
        for dep in sorted(g._dependents.get(cur, ())):
            indeg[dep] -= 1
            if indeg[dep] == 0:
                q.append(dep)
    if len(out) != len(g._nodes):
        raise ValueError("cycle")
    return out
