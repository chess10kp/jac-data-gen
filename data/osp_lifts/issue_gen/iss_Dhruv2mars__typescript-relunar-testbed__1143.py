"""Dhruv2mars/typescript-relunar-testbed#1143 — Recursive closure JSDoc inference graph.

TypeScript ignores @returns/@type annotations when an inner closure recursively
references itself. The checker models callable symbols as a reference adjacency
graph with outer→inner closure pointers; deque walks resolve transitive type
references while stack DFS detects inference cycles that block bare inference.
"""

from __future__ import annotations

from collections import deque


class InferenceGraph:
    def __init__(self) -> None:
        self._symbols: set[str] = set()
        self._refs: dict[str, list[str]] = {}
        self._closure_child: dict[str, str] = {}
        self._jsdoc: dict[str, str] = {}


def load_inference_graph(
    symbols: list[str],
    refs: list[tuple[str, str]],
    closure_returns: list[tuple[str, str]],
    jsdoc_returns: dict[str, str] | None = None,
) -> InferenceGraph:
    g = InferenceGraph()
    for sym in symbols:
        g._symbols.add(sym)
        g._refs.setdefault(sym, [])
    for src, dst in refs:
        if src in g._symbols and dst in g._symbols:
            g._refs.setdefault(src, []).append(dst)
    for outer, inner in closure_returns:
        if outer in g._symbols and inner in g._symbols:
            g._closure_child[outer] = inner
            g._refs.setdefault(outer, []).append(inner)
    for sym, ann in (jsdoc_returns or {}).items():
        if sym in g._symbols:
            g._jsdoc[sym] = ann
    return g


def reference_closure(g: InferenceGraph, symbol: str) -> list[str]:
    if symbol not in g._symbols:
        return []
    q: deque[str] = deque([symbol])
    claimed: set[str] = set()
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for nxt in sorted(g._refs.get(cur, [])):
            if nxt not in claimed:
                q.append(nxt)
    return sorted(hits)


def has_inference_cycle(g: InferenceGraph, symbol: str) -> bool:
    if symbol not in g._symbols:
        return False
    visiting: set[str] = set()

    def dfs(node: str) -> bool:
        if node in visiting:
            return True
        if node not in g._symbols:
            return False
        visiting.add(node)
        for nxt in g._refs.get(node, []):
            if dfs(nxt):
                return True
        visiting.discard(node)
        return False

    return dfs(symbol)


def effective_return_type(g: InferenceGraph, symbol: str) -> str | None:
    if symbol not in g._symbols:
        return None
    if symbol in g._jsdoc:
        return g._jsdoc[symbol]
    if has_inference_cycle(g, symbol):
        return None
    refs = sorted(g._refs.get(symbol, []))
    return refs[0] if refs else None


def returned_closure(g: InferenceGraph, outer: str) -> str | None:
    if outer not in g._symbols:
        return None
    return g._closure_child.get(outer)
