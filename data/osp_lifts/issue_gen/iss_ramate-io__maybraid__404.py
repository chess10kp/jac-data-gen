"""ramate-io/maybraid#404 — MultiMesh ChildOf hierarchy validation."""

from __future__ import annotations


class MeshStore:
    # Parent/child pointers for multi-mesh entity hierarchy.
    def __init__(self) -> None:
        self._entities: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}


def load_mesh(
    entity_ids: list[str],
    child_of_edges: list[tuple[str, str]],
) -> MeshStore:
    ms = MeshStore()
    for eid in entity_ids:
        ms._entities.add(eid)
        ms._parent[eid] = None
        ms._children.setdefault(eid, [])
    for parent, child in child_of_edges:
        if parent not in ms._entities or child not in ms._entities:
            continue
        ms._parent[child] = parent
        if child not in ms._children[parent]:
            ms._children[parent].append(child)
    return ms


def descendants(store: MeshStore, entity: str) -> list[str]:
    if entity not in store._entities:
        return []
    seen: set[str] = set()
    stack = [entity]
    while stack:
        cur = stack.pop()
        for ch in store._children.get(cur, []):
            if ch not in seen:
                seen.add(ch)
                stack.append(ch)
    return sorted(seen)


def validate_no_cycles(store: MeshStore) -> bool:
    for start in store._entities:
        visited: set[str] = set()
        stack = [start]
        while stack:
            cur = stack.pop()
            if cur in visited:
                return False
            visited.add(cur)
            for ch in store._children.get(cur, []):
                stack.append(ch)
        if len(visited) > len(descendants(store, start)) + 1:
            return False
    # Explicit cycle check via parent walk.
    for entity in store._entities:
        seen: set[str] = set()
        cur: str | None = entity
        while cur is not None:
            if cur in seen:
                return False
            seen.add(cur)
            cur = store._parent.get(cur)
    return True


def member_count(store: MeshStore, root: str) -> int:
    if root not in store._entities:
        return 0
    return len(descendants(store, root)) + 1
