"""Typed upgrade patches: semantic frontier over schema deps. kofun-lang/kofun#885."""

from __future__ import annotations

from collections import defaultdict, deque


class SchemaGraph:
    def __init__(self) -> None:
        self.parent: dict[str, str | None] = {}
        self.deps: dict[str, list[str]] = defaultdict(list)


def build_schema_graph(
    fields: list[str], depends: list[tuple[str, str]]
) -> SchemaGraph:
    g = SchemaGraph()
    for f in fields:
        g.parent.setdefault(f, None)
    for child, parent in depends:
        g.parent[child] = parent
        g.deps[parent].append(child)
    return g


def ancestors(graph: SchemaGraph, field: str) -> list[str]:
    if field not in graph.parent:
        return []
    out: list[str] = []
    cur = field
    while graph.parent.get(cur) is not None:
        cur = graph.parent[cur]  # type: ignore[assignment]
        out.append(cur)
    return out


def semantic_frontier(graph: SchemaGraph, changed: list[str]) -> list[str]:
    # BFS over depends edges from changed seeds; multiset order unspecified.
    seen: set[str] = set()
    q: deque[str] = deque()
    for c in changed:
        if c in graph.parent:
            q.append(c)
            seen.add(c)
    out: set[str] = set()
    while q:
        cur = q.popleft()
        for dep in graph.deps.get(cur, []):
            if dep not in seen:
                seen.add(dep)
                out.add(dep)
                q.append(dep)
    return sorted(out)
