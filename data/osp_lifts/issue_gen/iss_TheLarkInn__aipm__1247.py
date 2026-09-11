"""TheLarkInn/aipm#1247 — Cargo build-unit dependency graph for timing reports.

Build performance analysis over a hand-rolled adjacency graph: transitive
dependency closure, downstream fan-out (reverse reach), duplicate crate bases,
and TLS-chain path enumeration.
"""

from __future__ import annotations

from collections import deque


class BuildGraph:
    def __init__(self) -> None:
        self.times: dict[str, float] = {}
        self.deps: dict[str, list[str]] = {}

    def add_unit(self, name: str, seconds: float = 0.0) -> None:
        self.times[name] = seconds
        self.deps.setdefault(name, [])

    def add_edge(self, consumer: str, dep: str) -> None:
        if consumer in self.deps and dep in self.times:
            self.deps[consumer].append(dep)


def load_build_graph(
    units: list[tuple[str, float]],
    edges: list[tuple[str, str]],
) -> BuildGraph:
    g = BuildGraph()
    for name, secs in units:
        g.add_unit(name, secs)
    for src, dst in edges:
        g.add_edge(src, dst)
    return g


def _base_name(unit: str) -> str:
    if "@" in unit:
        return unit.split("@", 1)[0]
    return unit


def transitive_deps(g: BuildGraph, root: str) -> list[str]:
    if root not in g.times:
        return []
    seen: set[str] = {root}
    found: set[str] = set()
    queue: deque[str] = deque(g.deps.get(root, []))
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        found.add(cur)
        queue.extend(g.deps.get(cur, []))
    return sorted(found)


def downstream_units(g: BuildGraph, root: str) -> list[str]:
    if root not in g.times:
        return []
    reverse: dict[str, list[str]] = {u: [] for u in g.times}
    for consumer, deps in g.deps.items():
        for dep in deps:
            reverse.setdefault(dep, []).append(consumer)
    seen: set[str] = {root}
    found: set[str] = set()
    queue: deque[str] = deque(reverse.get(root, []))
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        found.add(cur)
        queue.extend(reverse.get(cur, []))
    return sorted(found)


def duplicate_base_names(g: BuildGraph) -> list[str]:
    buckets: dict[str, set[str]] = {}
    for unit in g.times:
        base = _base_name(unit)
        buckets.setdefault(base, set()).add(unit)
    return sorted(base for base, variants in buckets.items() if len(variants) > 1)


def dependency_paths(
    g: BuildGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]]:
    if source not in g.times or target not in g.times:
        return []
    out: list[list[str]] = []
    stack: list[tuple[str, list[str]]] = [(source, [source])]
    while stack:
        node, trail = stack.pop()
        if node == target:
            out.append(trail)
            continue
        if len(trail) >= max_depth:
            continue
        for nxt in g.deps.get(node, []):
            if nxt not in trail:
                stack.append((nxt, trail + [nxt]))
    return sorted(out)


def slowest_units(g: BuildGraph, threshold: float) -> list[tuple[str, float]]:
    hot = [(n, g.times[n]) for n in g.times if g.times[n] >= threshold]
    return sorted(hot, key=lambda row: (-row[1], row[0]))
