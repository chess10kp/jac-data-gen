"""DependencyTrack/dependency-track#3452 — Component dependency graph reachability."""

from __future__ import annotations

from collections import deque


class DepGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._deps: dict[str, list[str]] = {}
        self._rev: dict[str, list[str]] = {}


def load_dep_graph(
    components: list[str],
    depends_edges: list[tuple[str, str]],
) -> DepGraph:
    g = DepGraph()
    for cid in components:
        g._nodes.add(cid)
        g._deps.setdefault(cid, [])
        g._rev.setdefault(cid, [])
    for parent, child in depends_edges:
        if parent not in g._nodes or child not in g._nodes:
            continue
        g._deps[parent].append(child)
        g._rev[child].append(parent)
    return g


def _recursive_desc(store: DepGraph, root: str, acc: set[str]) -> None:
    for ch in sorted(store._deps.get(root, [])):
        if ch in acc:
            continue
        acc.add(ch)
        _recursive_desc(store, ch, acc)


def forward_closure(store: DepGraph, component_id: str) -> list[str]:
    if component_id not in store._nodes:
        return []
    seen: set[str] = {component_id}
    q: deque[str] = deque([component_id])
    while q:
        cur = q.popleft()
        for ch in store._deps.get(cur, []):
            if ch not in seen:
                seen.add(ch)
                q.append(ch)
    closure = set(seen)
    _recursive_desc(store, component_id, closure)
    return sorted(closure)


def reverse_introducers(store: DepGraph, leaf_id: str) -> list[str]:
    if leaf_id not in store._nodes:
        return []
    seen: set[str] = {leaf_id}
    q: deque[str] = deque([leaf_id])
    while q:
        cur = q.popleft()
        for par in store._rev.get(cur, []):
            if par not in seen:
                seen.add(par)
                q.append(par)
    return sorted(seen)
