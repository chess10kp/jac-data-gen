"""EffortlessMetrics/perl-lsp-swarm#10860 — execution-owner on reference occurrences."""

from __future__ import annotations


class RefStore:
    def __init__(self) -> None:
        self.children: dict[str, list[str]] = {}
        self.refs_by_unit: dict[str, list[str]] = {}
        self.owners: dict[str, str] = {}
        self.units: set[str] = set()


def load_refstore(
    units: list[tuple[str, str | None]],
    refs: list[tuple[str, str, str]],
) -> RefStore:
    # units: (uid, parent_uid); refs: (ref_id, unit_uid, callee)
    s = RefStore()
    for uid, par in units:
        s.units.add(uid)
        s.children.setdefault(uid, [])
        s.refs_by_unit.setdefault(uid, [])
        if par is not None:
            s.children.setdefault(par, []).append(uid)
    for ref_id, unit_uid, _callee in refs:
        if unit_uid in s.units:
            s.refs_by_unit.setdefault(unit_uid, []).append(ref_id)
    return s


def assign_owners(store: RefStore, root_id: str) -> None:
    stack: list[str] = []

    def visit(uid: str) -> None:
        stack.append(uid)
        for rid in store.refs_by_unit.get(uid, []):
            store.owners[rid] = stack[-1]
        for child in sorted(store.children.get(uid, [])):
            visit(child)
        stack.pop()

    if root_id in store.units:
        visit(root_id)


def owner_of(store: RefStore, ref_id: str) -> str:
    return store.owners.get(ref_id, "")


def refs_for_owner(store: RefStore, owner_id: str) -> list[str]:
    return sorted(rid for rid, ow in store.owners.items() if ow == owner_id)
