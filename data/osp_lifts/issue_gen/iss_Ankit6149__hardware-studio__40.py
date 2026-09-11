"""Ankit6149/hardware-studio#40 — Product graph impact and ancestor trace."""

from __future__ import annotations

from collections import deque


class ProductGraph:
    def __init__(self) -> None:
        self._parts: set[str] = set()
        self._parent: dict[str, str] = {}
        self._children: dict[str, list[str]] = {}
        self._depends: dict[str, list[str]] = {}


def load_product_graph(
    parts: list[str],
    contains_edges: list[tuple[str, str]],
    depends_edges: list[tuple[str, str]],
) -> ProductGraph:
    g = ProductGraph()
    for pid in parts:
        g._parts.add(pid)
        g._children.setdefault(pid, [])
        g._depends.setdefault(pid, [])
    for parent, child in contains_edges:
        if parent not in g._parts or child not in g._parts:
            continue
        g._parent[child] = parent
        g._children.setdefault(parent, []).append(child)
    for src, dst in depends_edges:
        if src not in g._parts or dst not in g._parts:
            continue
        g._depends[src].append(dst)
    return g


def impact_set(g: ProductGraph, part_id: str) -> list[str]:
    if part_id not in g._parts:
        return []
    seen: set[str] = {part_id}
    q: deque[str] = deque([part_id])
    while q:
        cur = q.popleft()
        for ch in g._children.get(cur, []):
            if ch not in seen:
                seen.add(ch)
                q.append(ch)
        for dep in g._depends.get(cur, []):
            if dep not in seen:
                seen.add(dep)
                q.append(dep)
    return sorted(seen)


def ancestor_trace(g: ProductGraph, part_id: str) -> list[str]:
    if part_id not in g._parts:
        return []
    chain: list[str] = [part_id]
    claimed: set[str] = {part_id}
    cur = part_id
    while True:
        parent = g._parent.get(cur)
        if parent is None or parent in claimed:
            break
        claimed.add(parent)
        chain.append(parent)
        cur = parent
    return chain
