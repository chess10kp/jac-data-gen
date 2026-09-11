"""guevara/read-it-later#7153 — nested-set hierarchy range queries."""

from __future__ import annotations


class NestedSetStore:
    def __init__(self) -> None:
        self._nodes: dict[str, tuple[int, int]] = {}
        self._parent_of: dict[str, str | None] = {}


def load_nested_set(
    entries: list[tuple[str, int, int, str | None]],
) -> NestedSetStore:
    store = NestedSetStore()
    for name, lft, rgt, parent in entries:
        store._nodes[name] = (lft, rgt)
        store._parent_of[name] = parent
    return store


def nested_subtree(store: NestedSetStore, root: str) -> list[str]:
    bounds = store._nodes.get(root)
    if bounds is None:
        return []
    lft, rgt = bounds
    out: list[str] = []
    for name, (nl, nr) in store._nodes.items():
        if nl >= lft and nr <= rgt:
            out.append(name)
    return sorted(out)


def nested_ancestors(store: NestedSetStore, node: str) -> list[str]:
    bounds = store._nodes.get(node)
    if bounds is None:
        return []
    nl, nr = bounds
    out: list[str] = []
    for name, (lft, rgt) in store._nodes.items():
        if lft < nl and rgt > nr:
            out.append(name)
    return sorted(out, key=lambda n: store._nodes[n][0])


def nested_depth(store: NestedSetStore, node: str) -> int:
    return len(nested_ancestors(store, node))


def contains_node(store: NestedSetStore, ancestor: str, descendant: str) -> bool:
    a = store._nodes.get(ancestor)
    d = store._nodes.get(descendant)
    if a is None or d is None:
        return False
    al, ar = a
    dl, dr = d
    return al <= dl and dr <= ar
