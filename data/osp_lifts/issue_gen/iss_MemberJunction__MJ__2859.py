"""MemberJunction/MJ#2859 — queryable typed metadata dependency graph."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple


class MetadataGraph:
    def __init__(self) -> None:
        self._entities: Set[str] = set()
        self._kinds: Dict[str, str] = {}
        self._deps: Dict[str, List[str]] = {}
        self._rev: Dict[str, List[str]] = {}


def load_graph(
    entities: List[Tuple[str, str]],
    edges: List[Tuple[str, str]],
) -> MetadataGraph:
    g = MetadataGraph()
    for eid, kind in entities:
        g._entities.add(eid)
        g._kinds[eid] = kind
        g._deps.setdefault(eid, [])
        g._rev.setdefault(eid, [])
    for src, dst in edges:
        if src not in g._entities or dst not in g._entities:
            continue
        if dst not in g._deps[src]:
            g._deps[src].append(dst)
        if src not in g._rev[dst]:
            g._rev[dst].append(src)
    return g


def _downstream(g: MetadataGraph, start: str) -> List[str]:
    seen: Set[str] = set()
    out: List[str] = []
    work: deque[str] = deque([start])
    while work:
        cur = work.popleft()
        for dep in sorted(g._deps.get(cur, [])):
            if dep not in seen:
                seen.add(dep)
                out.append(dep)
                work.append(dep)
    return sorted(out)


def _upstream(g: MetadataGraph, start: str) -> List[str]:
    seen: Set[str] = set()
    out: List[str] = []
    work: deque[str] = deque([start])
    while work:
        cur = work.popleft()
        for dep in sorted(g._rev.get(cur, [])):
            if dep not in seen:
                seen.add(dep)
                out.append(dep)
                work.append(dep)
    return sorted(out)


def dependencies(g: MetadataGraph, entity_id: str) -> List[str]:
    if entity_id not in g._entities:
        return []
    return _downstream(g, entity_id)


def dependents(g: MetadataGraph, entity_id: str) -> List[str]:
    if entity_id not in g._entities:
        return []
    return _upstream(g, entity_id)


def path_between(g: MetadataGraph, src: str, dst: str) -> List[str] | None:
    if src not in g._entities or dst not in g._entities:
        return None
    if src == dst:
        return [src]
    parent: Dict[str, str | None] = {src: None}
    work: deque[str] = deque([src])
    while work:
        cur = work.popleft()
        for nxt in sorted(g._deps.get(cur, [])):
            if nxt in parent:
                continue
            parent[nxt] = cur
            if nxt == dst:
                path: List[str] = []
                at: str | None = dst
                while at is not None:
                    path.append(at)
                    at = parent[at]
                return list(reversed(path))
            work.append(nxt)
    return None


def would_break(g: MetadataGraph, entity_id: str) -> List[str]:
    return dependents(g, entity_id)


def affected_by(g: MetadataGraph, changed: List[str]) -> List[str]:
    hit: Set[str] = set()
    for cid in changed:
        hit.update(would_break(g, cid))
    return sorted(hit)
