"""guevara/read-it-later#7152 — adjacency vs nested-set (MySQL EXPLAIN EXTENDED)."""

from __future__ import annotations

from collections import deque


class HierarchyModel:
    def __init__(self) -> None:
        self._parent_of: dict[str, str | None] = {}
        self._children_of: dict[str, list[str]] = {}
        self._bounds: dict[str, tuple[int, int]] = {}


def load_hierarchy(
    entries: list[tuple[str, int, int, str | None]],
) -> HierarchyModel:
    model = HierarchyModel()
    for name, lft, rgt, parent in entries:
        if parent is not None and parent not in model._parent_of:
            raise KeyError("unknown parent")
        model._bounds[name] = (lft, rgt)
        model._parent_of[name] = parent
        model._children_of.setdefault(name, [])
        if parent is not None:
            model._children_of.setdefault(parent, []).append(name)
    return model


def adj_session_descendants(model: HierarchyModel, root: str) -> list[str]:
    # Emulates MySQL session-variable rowwise descent without recursive CTE.
    if root not in model._parent_of:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for child in sorted(model._children_of.get(cur, [])):
            if child not in seen:
                seen.add(child)
                queue.append(child)
    return sorted(seen)


def nested_spatial_subtree(model: HierarchyModel, root: str) -> list[str]:
    # Emulates SPATIAL-index point-in-range lookup on nested-set bounds.
    bounds = model._bounds.get(root)
    if bounds is None:
        return []
    lft, rgt = bounds
    out: list[str] = []
    for name, (nl, nr) in model._bounds.items():
        if name == root:
            continue
        if nl >= lft and nr <= rgt:
            out.append(name)
    return sorted(out)


def adj_session_depth(model: HierarchyModel, node: str) -> int:
    if node not in model._parent_of:
        return -1
    depth = 0
    cur: str | None = node
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            return -1
        seen.add(cur)
        parent = model._parent_of.get(cur)
        if parent is None:
            break
        depth += 1
        cur = parent
    return depth


def nested_spatial_depth(model: HierarchyModel, node: str) -> int:
    bounds = model._bounds.get(node)
    if bounds is None:
        return -1
    nl, nr = bounds
    count = 0
    for name, (lft, rgt) in model._bounds.items():
        if name == node:
            continue
        if lft <= nl and nr <= rgt:
            count += 1
    return count


def models_agree_on_subtree(model: HierarchyModel, root: str) -> bool:
    return adj_session_descendants(model, root) == nested_spatial_subtree(model, root)
