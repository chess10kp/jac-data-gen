"""yaseen-vm/YAML-Visualizer#11 — detectCircularDeps skips missing service nodes."""

from __future__ import annotations


class ServiceGraph:
    def __init__(self) -> None:
        self._services: set[str] = set()
        self._depends: dict[str, list[str]] = {}


def load_services(
    services: list[str],
    depends_on: list[tuple[str, str]],
) -> ServiceGraph:
    g = ServiceGraph()
    for sid in services:
        g._services.add(sid)
        g._depends.setdefault(sid, [])
    for src, dep in depends_on:
        if src in g._services:
            g._depends.setdefault(src, []).append(dep)
    return g


def missing_deps(g: ServiceGraph) -> list[str]:
    missing: set[str] = set()
    for sid in g._services:
        for dep in g._depends.get(sid, []):
            if dep not in g._services:
                missing.add(dep)
    return sorted(missing)


def find_cycles(g: ServiceGraph) -> list[list[str]]:
    cycles: list[list[str]] = []
    visited: set[str] = set()
    stack: set[str] = set()
    path: list[str] = []

    def dfs(node: str) -> None:
        if node not in g._services:
            return
        if node in stack:
            if node in path:
                idx = path.index(node)
                cycles.append(path[idx:] + [node])
            return
        if node in visited:
            return
        visited.add(node)
        stack.add(node)
        path.append(node)
        for dep in g._depends.get(node, []):
            if dep in g._services:
                dfs(dep)
        path.pop()
        stack.remove(node)

    for sid in sorted(g._services):
        dfs(sid)
    uniq = sorted({tuple(c) for c in cycles})
    return [list(c) for c in uniq]


def has_cycle(g: ServiceGraph) -> bool:
    return len(find_cycles(g)) > 0
