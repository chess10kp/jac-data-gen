"""ELares/IronTraffic#147 — Reverse dependency dirty propagation for incremental compile."""

from __future__ import annotations

from collections import deque


class CompileGraph:
    def __init__(self) -> None:
        self._units: set[str] = set()
        self._depends: dict[str, list[str]] = {}
        self._dirty: set[str] = set()


def load_compile_graph(
    units: list[str],
    depends: list[tuple[str, str]],
) -> CompileGraph:
    g = CompileGraph()
    for uid in units:
        g._units.add(uid)
        g._depends.setdefault(uid, [])
    for upstream, downstream in depends:
        if upstream in g._units and downstream in g._units:
            g._depends.setdefault(downstream, []).append(upstream)
    return g


def reverse_dependents(graph: CompileGraph, unit_id: str) -> list[str]:
    if unit_id not in graph._units:
        return []
    rev: dict[str, list[str]] = {u: [] for u in graph._units}
    for downstream, ups in graph._depends.items():
        for up in ups:
            rev[up].append(downstream)
    seen: set[str] = set()
    queue: deque[str] = deque([unit_id])
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in rev.get(cur, []):
            if nxt not in seen:
                queue.append(nxt)
    return sorted(seen)


def mark_dirty(graph: CompileGraph, changed: list[str]) -> list[str]:
    dirty: set[str] = set()
    for uid in changed:
        if uid not in graph._units:
            continue
        for dep in reverse_dependents(graph, uid):
            dirty.add(dep)
    graph._dirty = dirty
    return sorted(dirty)


def is_dirty(graph: CompileGraph, unit_id: str) -> bool:
    return unit_id in graph._dirty
