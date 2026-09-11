"""duonghai258-beep/DT.BK_New#10 — Architecture layer dependency audit."""

from __future__ import annotations


class ArchGraph:
    def __init__(self) -> None:
        self._layers: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._layer_rank: dict[str, int] = {}


def load_arch_graph(
    layers: list[str],
    ranks: dict[str, int],
    deps: list[tuple[str, str]],
) -> ArchGraph:
    g = ArchGraph()
    for layer in layers:
        g._layers.add(layer)
        g._depends.setdefault(layer, [])
    g._layer_rank = dict(ranks)
    for src, dst in deps:
        if src in g._layers and dst in g._layers:
            g._depends.setdefault(src, []).append(dst)
    return g


def detect_cycles(graph: ArchGraph) -> list[tuple[str, str]]:
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

    for layer in sorted(graph._layers):
        if layer not in visited:
            dfs(layer)
    return sorted(errors)


def reverse_layer_violations(graph: ArchGraph) -> list[tuple[str, str]]:
    bad: list[tuple[str, str]] = []
    for src in sorted(graph._layers):
        src_rank = graph._layer_rank.get(src, 0)
        for dst in graph._depends.get(src, []):
            dst_rank = graph._layer_rank.get(dst, 0)
            if src_rank < dst_rank:
                bad.append((src, dst))
    return sorted(bad)


def upstream_closure(graph: ArchGraph, layer: str) -> list[str]:
    if layer not in graph._layers:
        return []
    seen: set[str] = {layer}
    stack = [layer]
    while stack:
        cur = stack.pop()
        for nxt in graph._depends.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                stack.append(nxt)
    return sorted(seen)
