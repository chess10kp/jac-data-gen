"""fiedl/wingolfsplattform#129 — DAG parent-child + transitive reach."""

from __future__ import annotations

from collections import deque


class DagStore:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}


def load_dag(
    nodes: list[str],
    edges: list[tuple[str, str]],
) -> DagStore:
    g = DagStore()
    for nid in nodes:
        g._nodes.add(nid)
        g._parent[nid] = None
        g._children.setdefault(nid, [])
    for parent, child in edges:
        if parent not in g._nodes or child not in g._nodes:
            continue
        g._parent[child] = parent
        g._children.setdefault(parent, []).append(child)
    return g


def _desc_bfs(g: DagStore, root: str) -> list[str]:
    if root not in g._nodes:
        return []
    q: deque[str] = deque([root])
    claimed: set[str] = set()
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for ch in g._children.get(cur, []):
            if ch not in claimed:
                q.append(ch)
    return hits


def descendants(g: DagStore, node_id: str) -> list[str]:
    return sorted(_desc_bfs(g, node_id))


def ancestors(g: DagStore, node_id: str) -> list[str]:
    if node_id not in g._nodes:
        return []
    chain: list[str] = [node_id]
    claimed: set[str] = {node_id}
    cur = node_id
    while True:
        parent = g._parent.get(cur)
        if parent is None or parent in claimed:
            break
        claimed.add(parent)
        chain.append(parent)
        cur = parent
    return chain


def reach(g: DagStore, src: str, dst: str) -> bool:
    return dst in _desc_bfs(g, src)
