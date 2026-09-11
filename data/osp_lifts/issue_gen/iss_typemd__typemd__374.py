"""typemd/typemd#374 — Single-hop relation field resolution for computed properties."""

from __future__ import annotations


class ObjectStore:
    def __init__(self) -> None:
        self._objects: dict[str, dict[str, str]] = {}
        self._relations: dict[str, dict[str, str | None]] = {}


def load_objects(
    entries: list[tuple[str, dict[str, str]]],
    relations: list[tuple[str, str, str | None]],
) -> ObjectStore:
    store = ObjectStore()
    for oid, fields in entries:
        store._objects[oid] = dict(fields)
        store._relations.setdefault(oid, {})
    for src, rel_name, tgt in relations:
        if src not in store._objects:
            continue
        store._relations.setdefault(src, {})[rel_name] = tgt
    return store


def related_id(store: ObjectStore, obj_id: str, rel_name: str) -> str | None:
    if obj_id not in store._objects:
        return None
    tgt = store._relations.get(obj_id, {}).get(rel_name)
    if tgt is None or tgt not in store._objects:
        return None
    return tgt


def resolve_field(store: ObjectStore, obj_id: str, dotted: str) -> str | None:
    if obj_id not in store._objects:
        return None
    parts = dotted.split(".", 1)
    if len(parts) == 1:
        return store._objects[obj_id].get(parts[0])
    rel_name, field = parts
    tgt = related_id(store, obj_id, rel_name)
    if tgt is None:
        return None
    return store._objects[tgt].get(field)
