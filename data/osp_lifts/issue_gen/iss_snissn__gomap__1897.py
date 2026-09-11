"""snissn/gomap#1897 — aligned fixed-width spans for TreeDB physical row assets.

Hand-rolled parent-child adjacency, dependency adjacency, deque lineage sweep
with offset ordering, and alignment/padding gate for fixed-width row spans.
"""

from __future__ import annotations

from collections import deque

class RowStore:
    def __init__(self) -> None:
        self._spans: dict[str, dict[str, int]] = {}
        self._parent_of: dict[str, str] = {}
        self._depends: dict[str, list[str]] = {}
        self._align: int = 8

def load_rows(
    spans: dict[str, dict[str, int]],
    parent_of: dict[str, str],
    depends: dict[str, list[str]],
    align: int = 8,
) -> RowStore:
    g = RowStore()
    g._spans = {k: dict(v) for k, v in spans.items()}
    g._parent_of = dict(parent_of)
    g._depends = {k: list(v) for k, v in depends.items()}
    g._align = align
    return g

def is_aligned(g: RowStore, span_id: str) -> bool:
    sp = g._spans.get(span_id)
    if sp is None:
        return False
    off = sp.get("offset", 0)
    width = sp.get("width", 0)
    return off % g._align == 0 and width % g._align == 0

def padding_bytes(g: RowStore, span_id: str) -> int:
    sp = g._spans.get(span_id)
    if sp is None:
        return 0
    rem = sp.get("offset", 0) % g._align
    return 0 if rem == 0 else g._align - rem

def lineage_closure(g: RowStore, root_id: str) -> list[str]:
    if root_id not in g._spans:
        return []
    children: dict[str, list[str]] = {}
    for child, parent in g._parent_of.items():
        if child in g._spans and parent in g._spans:
            children.setdefault(parent, []).append(child)
    seen: set[str] = set()
    work: deque[str] = deque(children.get(root_id, []))
    hits: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        work.extend(children.get(cur, []))
    return sorted(hits, key=lambda s: g._spans[s]["offset"])

def dependency_reach(g: RowStore, span_id: str) -> list[str]:
    if span_id not in g._spans:
        return []
    adj = {k: [d for d in v if d in g._spans] for k, v in g._depends.items()}
    seen: set[str] = set()
    work: deque[str] = deque(adj.get(span_id, []))
    hits: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        work.extend(adj.get(cur, []))
    return sorted(hits)
