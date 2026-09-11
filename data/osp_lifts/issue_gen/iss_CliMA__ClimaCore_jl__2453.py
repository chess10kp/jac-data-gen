"""CliMA/ClimaCore.jl#2453 — dependency graph for automatic tendency ordering and caching."""

from __future__ import annotations

from collections import deque
from typing import Any, Callable


class EagerGlobalCaching:
    pass


class LazyCaching:
    pass


class DependencyGraph:
    def __init__(self) -> None:
        self.nodes: set[str] = set()
        self.adj: dict[str, list[str]] = {}
        self.rev: dict[str, list[str]] = {}
        self.in_degree: dict[str, int] = {}
        self.roles: dict[str, str] = {}
        self.cache: dict[str, float] = {}


def build_dependency_graph(
    tend_names: list[str],
    prog_names: list[str],
    model: dict[str, Any],
) -> DependencyGraph:
    graph = DependencyGraph()
    var_deps: dict[str, tuple[str, ...]] = model["var_deps"]
    tend_deps: dict[str, tuple[str, ...]] = model["tend_deps"]

    for name in prog_names:
        graph.nodes.add(name)
        graph.adj.setdefault(name, [])
        graph.rev.setdefault(name, [])
        graph.in_degree.setdefault(name, 0)
        graph.roles[name] = "prog"

    for name in sorted(set(var_deps) | set(tend_names)):
        graph.nodes.add(name)
        graph.adj.setdefault(name, [])
        graph.rev.setdefault(name, [])
        graph.in_degree.setdefault(name, 0)
        if name in var_deps:
            graph.roles[name] = "computed"
        if name in tend_deps:
            graph.roles[name] = "tendency"

    def link(prereq: str, dependent: str) -> None:
        if prereq not in graph.nodes or dependent not in graph.nodes:
            raise KeyError(f"unknown node: {prereq!r} -> {dependent!r}")
        if dependent not in graph.adj[prereq]:
            graph.adj[prereq].append(dependent)
            graph.rev[dependent].append(prereq)
            graph.in_degree[dependent] = graph.in_degree.get(dependent, 0) + 1

    for var, deps in var_deps.items():
        for dep in deps:
            link(dep, var)
    for tend, deps in tend_deps.items():
        for dep in deps:
            link(dep, tend)
    return graph


def get_evaluation_order(graph: DependencyGraph) -> list[str] | None:
    indeg = {n: graph.in_degree.get(n, 0) for n in graph.nodes}
    q: deque[str] = deque(sorted(n for n, d in indeg.items() if d == 0))
    order: list[str] = []
    while q:
        cur = q.popleft()
        order.append(cur)
        for nxt in sorted(graph.adj.get(cur, [])):
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                q.append(nxt)
        q = deque(sorted(q))
    if len(order) != len(graph.nodes):
        return None
    return [n for n in order if graph.roles[n] != "prog"]


def dependency_chain(graph: DependencyGraph, name: str) -> list[str]:
    if name not in graph.nodes:
        return []
    seen: set[str] = set()
    q: deque[str] = deque(sorted(graph.rev.get(name, [])))
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        for up in sorted(graph.rev.get(cur, [])):
            if up not in seen:
                q.append(up)
    return sorted(hits)


def evaluate_graph(
    y_t: dict[str, float],
    y: dict[str, float],
    graph: DependencyGraph,
    model: dict[str, Any],
    t: float,
    strategy: object,
) -> None:
    order = get_evaluation_order(graph)
    if order is None:
        raise ValueError("cyclic dependency graph")
    workspace = dict(y)
    graph.cache.clear()
    eager = isinstance(strategy, EagerGlobalCaching)
    var_compute: dict[str, Callable[[dict[str, float], float], float]] = model["var_compute"]
    tend_compute: dict[str, Callable[[dict[str, float], float], float]] = model["tend_compute"]
    for node in order:
        if graph.roles[node] == "computed":
            val = var_compute[node](workspace, t)
            workspace[node] = val
            if eager:
                graph.cache[node] = val
        else:
            val = tend_compute[node](workspace, t)
            y_t[node] = val
            workspace[node] = val
            if eager:
                graph.cache[node] = val
