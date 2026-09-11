"""guevara/read-it-later#7154 — adjacency-list hierarchy queries."""

from __future__ import annotations

from collections import deque


class AdjHierarchy:
    def __init__(self) -> None:
        self._parent_of: dict[str, str | None] = {}
        self._children_of: dict[str, list[str]] = {}


def load_adjacency(
    nodes: list[tuple[str, str | None]],
) -> AdjHierarchy:
    tree = AdjHierarchy()
    for name, parent in nodes:
        if parent is not None and parent not in tree._parent_of:
            raise KeyError("unknown parent")
        tree._parent_of[name] = parent
        tree._children_of.setdefault(name, [])
        if parent is not None:
            tree._children_of.setdefault(parent, []).append(name)
    return tree


def adj_descendants(tree: AdjHierarchy, root: str) -> list[str]:
    if root not in tree._parent_of:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for child in sorted(tree._children_of.get(cur, [])):
            if child not in seen:
                seen.add(child)
                queue.append(child)
    return sorted(seen)


def adj_depth(tree: AdjHierarchy, node: str) -> int:
    if node not in tree._parent_of:
        return -1
    depth = 0
    cur: str | None = node
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            return -1
        seen.add(cur)
        parent = tree._parent_of.get(cur)
        if parent is None:
            break
        depth += 1
        cur = parent
    return depth


def adj_leaves(tree: AdjHierarchy) -> list[str]:
    out: list[str] = []
    for name in sorted(tree._parent_of):
        if not tree._children_of.get(name, []):
            out.append(name)
    return out
