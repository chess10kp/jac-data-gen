"""guillipa1993/spring-security#1 — Build module dependency cycle detection."""

from __future__ import annotations

from collections import deque


class BuildGraph:
    # Module adjacency for Gradle/Maven dependency edges in CI build graph.
    def __init__(self) -> None:
        self._modules: set[str] = set()
        self._depends: dict[str, list[str]] = {}


def load_build_graph(
    modules: list[str],
    depends_edges: list[tuple[str, str]],
) -> BuildGraph:
    g = BuildGraph()
    for m in modules:
        g._modules.add(m)
        g._depends.setdefault(m, [])
    for upstream, downstream in depends_edges:
        if upstream in g._modules and downstream in g._modules:
            g._depends.setdefault(downstream, []).append(upstream)
            g._depends.setdefault(upstream, g._depends.get(upstream, []))
    return g


def detect_build_cycles(store: BuildGraph) -> list[tuple[str, str]]:
    errors: list[tuple[str, str]] = []
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> None:
        visited.add(node)
        stack.add(node)
        for dep in store._depends.get(node, []):
            if dep in stack:
                errors.append((node, dep))
            elif dep not in visited:
                dfs(dep)
        stack.remove(node)

    for m in sorted(store._modules):
        if m not in visited:
            dfs(m)
    return sorted(errors)


def build_order_depth(store: BuildGraph, module: str) -> int:
    if module not in store._modules:
        return -1
    depth: dict[str, int] = {module: 0}
    queue: deque[str] = deque([module])
    best = 0
    while queue:
        cur = queue.popleft()
        for dep in store._depends.get(cur, []):
            nd = depth[cur] + 1
            if nd > best:
                best = nd
            if dep not in depth or nd > depth[dep]:
                depth[dep] = nd
                queue.append(dep)
    return best
