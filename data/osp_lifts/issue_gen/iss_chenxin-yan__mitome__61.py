"""chenxin-yan/mitome#61 — Extension dependency graph with load order."""

from __future__ import annotations


class ExtensionGraph:
    def __init__(self) -> None:
        self._extensions: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._provides: dict[str, list[str]] = {}


def load_extension_graph(
    names: list[str],
    depends: list[tuple[str, str]],
    provides: dict[str, list[str]] | None = None,
) -> ExtensionGraph:
    g = ExtensionGraph()
    for name in names:
        g._extensions.add(name)
        g._depends.setdefault(name, [])
        g._provides[name] = list((provides or {}).get(name, []))
    for dep, ext in depends:
        if dep in g._extensions and ext in g._extensions:
            g._depends.setdefault(ext, []).append(dep)
    return g


def detect_extension_cycles(graph: ExtensionGraph) -> list[tuple[str, str]]:
    errors: list[tuple[str, str]] = []
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> None:
        visited.add(node)
        stack.add(node)
        for nxt in graph._depends.get(node, []):
            if nxt in stack:
                errors.append((node, nxt))
            elif nxt not in visited:
                dfs(nxt)
        stack.remove(node)

    for ext in sorted(graph._extensions):
        if ext not in visited:
            dfs(ext)
    return sorted(errors)


def resolve_load_order(graph: ExtensionGraph) -> list[str]:
    indeg: dict[str, int] = {e: 0 for e in graph._extensions}
    rev: dict[str, list[str]] = {e: [] for e in graph._extensions}
    for ext in graph._extensions:
        for dep in graph._depends.get(ext, []):
            indeg[ext] += 1
            rev[dep].append(ext)
    ready = sorted(e for e in graph._extensions if indeg[e] == 0)
    order: list[str] = []
    while ready:
        cur = ready.pop(0)
        order.append(cur)
        for nxt in sorted(rev.get(cur, [])):
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                ready.append(nxt)
                ready.sort()
    return order if len(order) == len(graph._extensions) else []


def transitive_dependencies(graph: ExtensionGraph, ext_id: str) -> list[str]:
    if ext_id not in graph._extensions:
        return []
    seen: set[str] = set()
    stack = [ext_id]

    def collect(node: str) -> None:
        for dep in graph._depends.get(node, []):
            if dep not in seen:
                seen.add(dep)
                collect(dep)

    collect(ext_id)
    return sorted(seen)
