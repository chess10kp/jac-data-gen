"""cyberchitta/llm-context.py#25 — Rule-driven context lacks import-graph expansion.

Hand-rolled adjacency dict + deque BFS for transitive import reachability,
stack-based import-path enumeration, kind-grouped impact summaries, and
token-budget preview over a synthetic repository graph (lc-preview / lc-impact).
"""

from __future__ import annotations

from collections import deque


class ContextGraph:
    def __init__(self) -> None:
        self.kb: dict[str, float] = {}
        self.kind: dict[str, str] = {}
        self.imports: dict[str, list[str]] = {}


def load_context_graph(
    files: list[tuple[str, str, float]],
    edges: list[tuple[str, str]],
) -> ContextGraph:
    g = ContextGraph()
    for path, kind, weight_kb in files:
        g.kb[path] = weight_kb
        g.kind[path] = kind
        g.imports.setdefault(path, [])
    for src, dst in edges:
        if src in g.imports and dst in g.kb:
            g.imports[src].append(dst)
    return g


def transitive_imports(g: ContextGraph, entry: str) -> list[str]:
    if entry not in g.kb:
        return []
    seen: set[str] = {entry}
    found: set[str] = set()
    queue: deque[str] = deque(g.imports.get(entry, []))
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        found.add(cur)
        queue.extend(g.imports.get(cur, []))
    return sorted(found)


def import_paths(
    g: ContextGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]]:
    if source not in g.kb or target not in g.kb:
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
        for nxt in g.imports.get(node, []):
            if nxt not in trail:
                stack.append((nxt, trail + [nxt]))
    return sorted(out)


def impact_by_kind(g: ContextGraph, entry: str) -> dict[str, list[str]]:
    buckets: dict[str, list[str]] = {}
    for path in transitive_imports(g, entry):
        kind = g.kind.get(path, "unknown")
        buckets.setdefault(kind, []).append(path)
    return {k: sorted(v) for k, v in sorted(buckets.items())}


def preview_token_kb(g: ContextGraph, entry: str) -> float:
    if entry not in g.kb:
        return 0.0
    total = g.kb[entry]
    for path in transitive_imports(g, entry):
        total += g.kb[path]
    return total


def rule_context_files(
    g: ContextGraph,
    seeds: list[str],
    *,
    expand_deps: bool = True,
) -> list[str]:
    chosen: set[str] = set()
    for seed in seeds:
        if seed not in g.kb:
            continue
        chosen.add(seed)
        if expand_deps:
            for dep in transitive_imports(g, seed):
                chosen.add(dep)
    return sorted(chosen)
