"""EffortlessMetrics/perl-lsp-swarm#8769 — Phase-labelled module compile reach."""

from __future__ import annotations

from collections import deque


class ModuleGraph:
    def __init__(self) -> None:
        self._mods: set[str] = set()
        self._compile: dict[str, list[str]] = {}


def load_module_graph(
    modules: list[str],
    compile_edges: list[tuple[str, str]],
) -> ModuleGraph:
    g = ModuleGraph()
    for mid in modules:
        g._mods.add(mid)
        g._compile.setdefault(mid, [])
    for src, dst in compile_edges:
        if src not in g._mods or dst not in g._mods:
            continue
        g._compile[src].append(dst)
    return g


def compile_reach(g: ModuleGraph, root_id: str) -> list[str]:
    if root_id not in g._mods:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([root_id])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g._compile.get(cur, []):
            if nxt not in seen:
                q.append(nxt)
    return sorted(seen)


def compile_levels(g: ModuleGraph, root_id: str) -> list[list[str]]:
    if root_id not in g._mods:
        return []
    levels: list[list[str]] = [[root_id]]
    seen: set[str] = {root_id}
    frontier = [root_id]
    while frontier:
        nxt: list[str] = []
        for cur in frontier:
            for dep in sorted(g._compile.get(cur, [])):
                if dep not in seen:
                    seen.add(dep)
                    nxt.append(dep)
        if not nxt:
            break
        levels.append(sorted(nxt))
        frontier = nxt
    return levels
