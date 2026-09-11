"""xqvzntrp/20260820t#48 — Composition graph walk loops on cyclic component trees."""

from __future__ import annotations

from collections import deque


class ComponentGraph:
    # Fresh handle per test; hand-rolled composes adjacency.
    def __init__(self) -> None:
        self.components: dict[str, str] = {}
        self.composes: dict[str, list[str]] = {}


def load_components(
    components: list[tuple[str, str]],
    edges: list[tuple[str, str]],
) -> ComponentGraph:
    g = ComponentGraph()
    for cid, label in components:
        g.components[cid] = label
        g.composes.setdefault(cid, [])
    for parent, child in edges:
        if parent in g.components and child in g.components:
            g.composes.setdefault(parent, []).append(child)
    return g


def composition_chain(g: ComponentGraph, root: str) -> list[str]:
    # Queue walk with visited-set; returns sorted reachable component ids.
    if root not in g.components:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([root])
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        for nxt in sorted(g.composes.get(cur, [])):
            if nxt not in seen:
                q.append(nxt)
    return sorted(hits)


def has_composition_cycle(g: ComponentGraph, root: str) -> bool:
    if root not in g.components:
        return False
    visiting: set[str] = set()
    seen: set[str] = set()

    def dfs(cid: str) -> bool:
        if cid in visiting:
            return True
        if cid in seen:
            return False
        visiting.add(cid)
        for nxt in g.composes.get(cid, []):
            if dfs(nxt):
                return True
        visiting.remove(cid)
        seen.add(cid)
        return False

    return dfs(root)
