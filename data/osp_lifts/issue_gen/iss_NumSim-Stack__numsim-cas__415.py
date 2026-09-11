"""NumSim-Stack/numsim-cas#415 — lazy subtree hash with auto invalidation in mutators."""

from __future__ import annotations


class TreeStore:
    def __init__(self) -> None:
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._value: dict[str, int] = {}
        self._cache: dict[str, int | None] = {}
        self._nodes: set[str] = set()


def load_tree(nodes: list[tuple[str, int, str | None]]) -> TreeStore:
    g = TreeStore()
    for nid, val, _par in nodes:
        g._nodes.add(nid)
        g._parent.setdefault(nid, None)
        g._children.setdefault(nid, [])
        g._value[nid] = val
        g._cache[nid] = None
    for nid, val, par in nodes:
        g._value[nid] = val
        if par is not None and par in g._nodes:
            g._parent[nid] = par
            g._children.setdefault(par, []).append(nid)
    return g


def _compute_hash(g: TreeStore, nid: str) -> int:
    h = g._value[nid]
    for ch in sorted(g._children.get(nid, [])):
        h = (h * 31 + _compute_hash(g, ch)) & 0xFFFFFFFF
    g._cache[nid] = h
    return h


def subtree_hash(g: TreeStore, nid: str) -> int:
    if nid not in g._nodes:
        return 0
    cached = g._cache.get(nid)
    if cached is not None:
        return cached
    return _compute_hash(g, nid)


def _invalidate(g: TreeStore, nid: str) -> None:
    cur: str | None = nid
    while cur is not None:
        g._cache[cur] = None
        cur = g._parent.get(cur)


def set_value(g: TreeStore, nid: str, value: int) -> None:
    if nid not in g._nodes:
        return
    g._value[nid] = value
    _invalidate(g, nid)


def add_child(g: TreeStore, parent: str, child: str, value: int) -> None:
    if parent not in g._nodes or child in g._nodes:
        return
    g._nodes.add(child)
    g._parent[child] = parent
    g._children.setdefault(parent, []).append(child)
    g._children.setdefault(child, [])
    g._value[child] = value
    g._cache[child] = None
    _invalidate(g, parent)


def dirty_nodes(g: TreeStore) -> list[str]:
    return sorted(n for n in g._nodes if g._cache.get(n) is None)
