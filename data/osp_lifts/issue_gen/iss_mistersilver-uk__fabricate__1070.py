"""mistersilver-uk/fabricate#1070 — component reachability for large crafting corpora."""

from __future__ import annotations

from collections import deque


class CraftGraph:
    def __init__(self) -> None:
        self._components: set[str] = set()
        self._requires: dict[str, list[str]] = {}
        self._kinds: dict[str, str] = {}


def load_craft_graph(
    components: list[tuple[str, str]],
    requires: list[tuple[str, str]],
) -> CraftGraph:
    g = CraftGraph()
    for cid, kind in components:
        g._components.add(cid)
        g._kinds[cid] = kind
        g._requires.setdefault(cid, [])
    for src, dep in requires:
        if src in g._components and dep in g._components:
            g._requires.setdefault(src, []).append(dep)
            g._requires.setdefault(dep, g._requires.get(dep, []))
    return g


def reachable_components(g: CraftGraph, start: str) -> list[str]:
    if start not in g._components:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([start])
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        for req in g._requires.get(cur, []):
            if req not in seen:
                q.append(req)
    return sorted(hits)


def components_by_kind(g: CraftGraph, start: str, kind: str) -> list[str]:
    return sorted([c for c in reachable_components(g, start) if g._kinds.get(c) == kind])


def invalidate_component(g: CraftGraph, cid: str) -> list[str]:
    if cid not in g._components:
        return []
    doomed: set[str] = set()
    stack: list[str] = [cid]
    while stack:
        cur = stack.pop()
        if cur in doomed:
            continue
        doomed.add(cur)
        for user in g._components:
            if cur in g._requires.get(user, []) and user not in doomed:
                stack.append(user)
    removed = sorted(doomed)
    for rid in removed:
        g._components.discard(rid)
        g._requires.pop(rid, None)
        g._kinds.pop(rid, None)
    return removed
