"""Teal-Insights/excel-grapher#353 — split serialization from caching.

Hand-rolled workbook dependency adjacency, pure recursive serialize,
separate cache dict, and deque downstream invalidation sweep.
"""

from __future__ import annotations

from collections import defaultdict, deque


class WorkbookStore:
    def __init__(self) -> None:
        self._specs: dict[str, dict] = {}
        self._deps: dict[str, list[str]] = defaultdict(list)
        self._rev: dict[str, list[str]] = defaultdict(list)
        self._cache: dict[str, str] = {}


def load_workbook(
    specs: dict[str, dict],
    edges: list[tuple[str, str]],
) -> WorkbookStore:
    g = WorkbookStore()
    g._specs = {k: dict(v) for k, v in specs.items()}
    for src, dst in edges:
        if src in g._specs and dst in g._specs:
            g._deps[src].append(dst)
            g._rev[dst].append(src)
    return g


def serialize_node(g: WorkbookStore, node_id: str) -> str:
    if node_id not in g._specs:
        return ""
    dep_parts: list[str] = []
    for dep in sorted(g._deps.get(node_id, [])):
        dep_parts.append(serialize_node(g, dep))
    kind = g._specs[node_id].get("kind", "sheet")
    return f"node:{node_id}|kind:{kind}|deps:[{','.join(dep_parts)}]"


def cached_serialize(g: WorkbookStore, node_id: str) -> str:
    if node_id not in g._specs:
        return ""
    hit = g._cache.get(node_id)
    if hit is not None:
        return hit
    val = serialize_node(g, node_id)
    g._cache[node_id] = val
    return val


def dependency_reach(g: WorkbookStore, node_id: str) -> list[str]:
    if node_id not in g._specs:
        return []
    seen: set[str] = set()
    work: deque[str] = deque([node_id])
    hits: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        for nxt in g._rev.get(cur, []):
            if nxt not in seen:
                work.append(nxt)
    return sorted(hits)


def invalidate_node(g: WorkbookStore, node_id: str) -> list[str]:
    victims = dependency_reach(g, node_id)
    for vid in victims:
        g._cache.pop(vid, None)
    return victims
