"""brylie/compendium#53 — Relationship and provenance edge fabric."""

from __future__ import annotations


class RelationStore:
    # Forward + reverse adjacency for typed reference edges.
    def __init__(self) -> None:
        self._entities: set[str] = set()
        self._forward: dict[str, list[tuple[str, str]]] = {}
        self._reverse: dict[str, list[tuple[str, str]]] = {}
        self._retired: set[tuple[str, str, str]] = set()


def load_entities(entity_ids: list[str]) -> RelationStore:
    rs = RelationStore()
    for eid in entity_ids:
        rs._entities.add(eid)
        rs._forward.setdefault(eid, [])
        rs._reverse.setdefault(eid, [])
    return rs


def create_ref(
    store: RelationStore,
    source: str,
    target: str,
    rel_type: str,
) -> bool:
    if source not in store._entities or target not in store._entities:
        return False
    key = (source, target, rel_type)
    if key in store._retired:
        store._retired.discard(key)
    store._forward.setdefault(source, []).append((target, rel_type))
    store._reverse.setdefault(target, []).append((source, rel_type))
    return True


def forward_refs(store: RelationStore, source: str) -> list[tuple[str, str]]:
    if source not in store._entities:
        return []
    out: list[tuple[str, str]] = []
    for tgt, rtype in store._forward.get(source, []):
        if (source, tgt, rtype) not in store._retired:
            out.append((tgt, rtype))
    return sorted(out)


def reverse_refs(store: RelationStore, target: str) -> list[tuple[str, str]]:
    if target not in store._entities:
        return []
    out: list[tuple[str, str]] = []
    for src, rtype in store._reverse.get(target, []):
        if (src, target, rtype) not in store._retired:
            out.append((src, rtype))
    return sorted(out)


def retire_ref(
    store: RelationStore,
    source: str,
    target: str,
    rel_type: str,
) -> bool:
    key = (source, target, rel_type)
    exists = any(t == target and r == rel_type for t, r in store._forward.get(source, []))
    if not exists:
        return False
    store._retired.add(key)
    return True
