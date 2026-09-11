"""nisshchayarathi/gitverse-nextjs#2095 — Circular import parsing with visited cache.

Module import graphs are walked with an adjacency dict; a visited set returns
cached nodes on cycle re-entry instead of infinite recursion.
"""

from __future__ import annotations


class ModuleGraph:
    def __init__(self) -> None:
        self.modules: set[str] = set()
        self.imports: dict[str, list[str]] = {}
        self.cache: dict[str, list[str]] = {}


def load_modules(
    modules: list[str],
    import_edges: list[tuple[str, str]],
) -> ModuleGraph:
    g = ModuleGraph()
    for mod in modules:
        g.modules.add(mod)
        g.imports.setdefault(mod, [])
    for src, dst in import_edges:
        if src in g.modules and dst in g.modules:
            g.imports.setdefault(src, []).append(dst)
            g.imports.setdefault(dst, g.imports.get(dst, []))
    return g


def _parse_imports(g: ModuleGraph, start: str, visited: set[str]) -> list[str]:
    if start in g.cache:
        return g.cache[start]
    if start in visited:
        return [start]
    visited.add(start)
    chain: list[str] = [start]
    for nxt in g.imports.get(start, []):
        for part in _parse_imports(g, nxt, visited):
            if part not in chain:
                chain.append(part)
    g.cache[start] = chain
    visited.discard(start)
    return chain


def import_closure(g: ModuleGraph, module_id: str) -> list[str]:
    if module_id not in g.modules:
        return []
    return sorted(set(_parse_imports(g, module_id, set())))


def has_cycle(g: ModuleGraph) -> bool:
    for mod in g.modules:
        seen: set[str] = set()
        stack: set[str] = set()

        def dfs(node: str) -> bool:
            if node in stack:
                return True
            if node in seen:
                return False
            seen.add(node)
            stack.add(node)
            for nxt in g.imports.get(node, []):
                if dfs(nxt):
                    return True
            stack.remove(node)
            return False

        if dfs(mod):
            return True
    return False
