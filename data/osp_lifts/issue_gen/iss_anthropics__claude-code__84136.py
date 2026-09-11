"""anthropics/claude-code#84136 — MCP initialize deadline vs uvx cold-start dependency graph."""

from __future__ import annotations

from collections import deque


class PkgGraph:
    def __init__(self) -> None:
        self.install_secs: dict[str, float] = {}
        self.deps: dict[str, list[str]] = {}
        self.parents: dict[str, list[str]] = {}
        self.packages: dict[str, str] = {}


def load_pkg_graph(
    packages: list[tuple[str, float]],
    edges: list[tuple[str, str]],
) -> PkgGraph:
    g = PkgGraph()
    for name, secs in packages:
        g.install_secs[name] = secs
        g.deps.setdefault(name, [])
        g.parents.setdefault(name, [])
        g.packages[name] = name
    for consumer, dep in edges:
        if consumer in g.install_secs and dep in g.install_secs:
            g.deps[consumer].append(dep)
            g.parents[dep].append(consumer)
    return g


def transitive_deps(g: PkgGraph, root: str) -> list[str]:
    if root not in g.install_secs:
        return []
    seen: set[str] = {root}
    found: list[str] = []
    queue: deque[str] = deque(sorted(g.deps.get(root, [])))
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        found.append(cur)
        for dep in sorted(g.deps.get(cur, [])):
            if dep not in seen:
                queue.append(dep)
    return sorted(found)


def install_order(g: PkgGraph, root: str) -> list[str]:
    if root not in g.install_secs:
        return []
    nodes: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        if cur in nodes:
            continue
        nodes.add(cur)
        for dep in g.deps.get(cur, []):
            if dep not in nodes:
                queue.append(dep)
    if not nodes:
        return []
    indeg: dict[str, int] = {n: 0 for n in nodes}
    for n in nodes:
        for dep in g.deps.get(n, []):
            if dep in nodes:
                indeg[n] += 1
    ready: deque[str] = deque(sorted(n for n in nodes if indeg[n] == 0))
    order: list[str] = []
    while ready:
        cur = ready.popleft()
        order.append(cur)
        for child in sorted(g.parents.get(cur, [])):
            if child not in nodes:
                continue
            indeg[child] -= 1
            if indeg[child] == 0:
                ready.append(child)
    return order if len(order) == len(nodes) else []


def cold_start_seconds(
    g: PkgGraph,
    root: str,
    cached: set[str] | None = None,
) -> float:
    warm = cached if cached is not None else set()
    total = 0.0
    for pkg in install_order(g, root):
        if pkg not in warm:
            total += g.install_secs[pkg]
    return total


def initialize_status(
    g: PkgGraph,
    root: str,
    deadline: float = 60.0,
    cached: set[str] | None = None,
) -> str:
    if root not in g.install_secs:
        return "cancelled"
    warm = cached if cached is not None else set()
    elapsed = 0.0
    for pkg in install_order(g, root):
        if pkg in warm:
            continue
        elapsed += g.install_secs[pkg]
        if elapsed > deadline:
            return "cancelled"
    return "ready"


def dependency_paths(
    g: PkgGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]]:
    if source not in g.install_secs or target not in g.install_secs:
        return []
    paths: list[list[str]] = []

    def walk(here: str, trail: list[str]) -> None:
        if here in trail:
            return
        nt = trail + [here]
        if here == target:
            paths.append(list(nt))
            return
        if len(nt) >= max_depth:
            return
        for dep in sorted(g.deps.get(here, [])):
            walk(dep, nt)

    walk(source, [])
    return sorted(paths)
