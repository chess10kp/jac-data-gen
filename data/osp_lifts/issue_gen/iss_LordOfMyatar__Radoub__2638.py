"""LordOfMyatar/Radoub#2638 — De-duplicate supermodel animation merge (QM + Reliquary).

Hand-rolled parent-child and depends adjacency, deque walk with visited-set,
and key/source dedup so converging QM/Reliquary paths do not double-merge.
"""

from __future__ import annotations

from collections import deque


class AnimGraph:
    # Fresh handle per test; clips lookup is domain API, not traversal scaffolding.
    def __init__(self) -> None:
        self.clips: dict[str, tuple[str, str]] = {}
        self.children: dict[str, list[str]] = {}
        self.deps: dict[str, list[str]] = {}


def load_animations(
    clips: list[tuple[str, str, str]],
    child_edges: list[tuple[str, str]],
    dep_edges: list[tuple[str, str]],
) -> AnimGraph:
    g = AnimGraph()
    for cid, key, source in clips:
        g.clips[cid] = (key, source)
        g.children.setdefault(cid, [])
        g.deps.setdefault(cid, [])
    for parent, child in child_edges:
        if parent in g.clips and child in g.clips:
            g.children.setdefault(parent, []).append(child)
    for src, dst in dep_edges:
        if src in g.clips and dst in g.clips:
            g.deps.setdefault(src, []).append(dst)
    return g


def _neighbors(g: AnimGraph, cid: str) -> list[str]:
    nbrs = list(g.children.get(cid, []))
    nbrs.extend(g.deps.get(cid, []))
    return sorted(nbrs)


def _merge_walk(g: AnimGraph, target: str) -> tuple[list[str], list[str]]:
    if target not in g.clips:
        return [], []
    seen_nodes: set[str] = set()
    seen_keys: set[str] = set()
    seen_sources: set[str] = set()
    keys: list[str] = []
    sources: list[str] = []
    q: deque[str] = deque([target])
    while q:
        cur = q.popleft()
        if cur in seen_nodes:
            continue
        seen_nodes.add(cur)
        key, source = g.clips[cur]
        if key and key not in seen_keys:
            seen_keys.add(key)
            keys.append(key)
        if source and source not in seen_sources:
            seen_sources.add(source)
            sources.append(source)
        for nxt in _neighbors(g, cur):
            if nxt in g.clips:
                q.append(nxt)
    return sorted(sources), sorted(keys)


def merge_sources(g: AnimGraph, target: str) -> list[str]:
    sources, _ = _merge_walk(g, target)
    return sources


def merged_keys(g: AnimGraph, target: str) -> list[str]:
    _, keys = _merge_walk(g, target)
    return keys
