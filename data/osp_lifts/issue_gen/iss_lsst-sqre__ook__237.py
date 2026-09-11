"""lsst-sqre/ook#237 — Intersphinx entity hierarchy navigation."""

from __future__ import annotations


class EntityStore:
    def __init__(self) -> None:
        self._entities: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._role: dict[str, str] = {}


def load_entities(
    names: list[str],
    roles: list[tuple[str, str]],
    parent_edges: list[tuple[str, str]],
) -> EntityStore:
    store = EntityStore()
    for name in names:
        store._entities.add(name)
        store._parent[name] = None
        store._children.setdefault(name, [])
        store._role[name] = "object"
    for name, role in roles:
        if name in store._entities:
            store._role[name] = role
    for child, parent in parent_edges:
        if child in store._entities and parent in store._entities:
            store._parent[child] = parent
            store._children.setdefault(parent, []).append(child)
    return store


def _descendants(store: EntityStore, root: str, seen: set[str]) -> list[str]:
    hits: list[str] = []
    stack = list(store._children.get(root, []))
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        for ch in store._children.get(cur, []):
            stack.append(ch)
    return hits


def direct_children(store: EntityStore, name: str) -> list[str]:
    if name not in store._entities:
        return []
    return sorted(store._children.get(name, []))


def all_descendants(store: EntityStore, name: str) -> list[str]:
    if name not in store._entities:
        return []
    seen: set[str] = {name}
    return sorted(_descendants(store, name, seen))


def ancestor_chain(store: EntityStore, name: str) -> list[str]:
    if name not in store._entities:
        return []
    chain: list[str] = []
    seen: set[str] = {name}
    cur = name
    while True:
        parent = store._parent.get(cur)
        if parent is None or parent in seen:
            break
        seen.add(parent)
        chain.append(parent)
        cur = parent
    return list(reversed(chain))


def entity_role(store: EntityStore, name: str) -> str | None:
    return store._role.get(name)
