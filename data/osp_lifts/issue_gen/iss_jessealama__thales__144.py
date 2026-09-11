"""jessealama/thales#144 — out-of-order tolerant top-level declaration emission."""
from __future__ import annotations
from dataclasses import dataclass, field

KIND_DEF = "def"
KIND_STRUCT = "structure"

@dataclass
class Decl:
    name: str
    kind: str
    source_idx: int

@dataclass
class EmissionStore:
    decls: dict[str, Decl] = field(default_factory=dict)
    prereqs: dict[str, set[str]] = field(default_factory=dict)
    dependents: dict[str, set[str]] = field(default_factory=dict)

def fresh_emission_store() -> EmissionStore:
    return EmissionStore()

def register_declaration(name: str, kind: str, source_idx: int, store: EmissionStore | None = None) -> EmissionStore:
    s = store if store is not None else fresh_emission_store()
    if name in s.decls:
        raise ValueError("duplicate declaration")
    s.decls[name] = Decl(name, kind, source_idx)
    s.prereqs.setdefault(name, set())
    s.dependents.setdefault(name, set())
    return s

def add_reference(from_decl: str, to_decl: str, store: EmissionStore) -> None:
    if from_decl not in store.decls or to_decl not in store.decls:
        raise KeyError("unknown declaration")
    if from_decl not in store.dependents.setdefault(to_decl, set()):
        store.prereqs.setdefault(from_decl, set()).add(to_decl)
        store.dependents[to_decl].add(from_decl)

def direct_references(name: str, store: EmissionStore) -> list[str]:
    if name not in store.decls:
        raise KeyError(name)
    return sorted(store.prereqs.get(name, set()))

def _claim_walk(store: EmissionStore, start: str, adj: dict[str, set[str]]) -> list[str]:
    if start not in store.decls:
        return []
    claimed: dict[str, bool] = {}
    reached: list[str] = []
    def step(here: str) -> None:
        if here in claimed:
            return
        claimed[here] = True
        reached.append(here)
        for nb in sorted(adj.get(here, ())):
            step(nb)
    step(start)
    return reached

def _prereq_walk(store: EmissionStore, start_id: str) -> list[str]:
    return _claim_walk(store, start_id, store.prereqs)

def _dependent_walk(store: EmissionStore, start_id: str) -> list[str]:
    return _claim_walk(store, start_id, store.dependents)

def mutual_recursion_groups(store: EmissionStore) -> list[list[str]]:
    assigned: dict[str, bool] = {}
    groups: list[list[str]] = []
    for n in sorted(store.decls):
        if n in assigned:
            continue
        fwd, rev = _dependent_walk(store, n), _prereq_walk(store, n)
        rev_set = {r: True for r in rev}
        comp = [m for m in fwd if rev_set.get(m)]
        for m in comp:
            assigned[m] = True
        if len(comp) > 1:
            groups.append(sorted(comp))
    groups.sort(key=lambda g: g[0])
    return groups

def prerequisite_order(store: EmissionStore) -> list[str] | None:
    indeg = {nm: len(store.prereqs.get(nm, ())) for nm in store.decls}
    order: list[str] = []
    while len(order) < len(indeg):
        picked = [nm for nm in sorted(indeg) if indeg[nm] == 0]
        if not picked:
            return None
        for nid in picked:
            order.append(nid)
            for succ in store.dependents.get(nid, ()):
                indeg[succ] -= 1
            indeg[nid] = -1
    return order

def hybrid_emit_plan(store: EmissionStore) -> dict:
    order, mutual = prerequisite_order(store), mutual_recursion_groups(store)
    mutual_members = {m: True for grp in mutual for m in grp}
    structs, linear_defs = [], []
    if order is not None:
        for nm in order:
            kind = store.decls[nm].kind
            if kind == KIND_STRUCT:
                structs.append(nm)
            elif kind == KIND_DEF and not mutual_members.get(nm):
                linear_defs.append(nm)
    return {"structures": structs, "linear_defs": linear_defs, "mutual_groups": mutual}

def classify_forward_reference(from_decl: str, to_decl: str, store: EmissionStore) -> str:
    if from_decl not in store.decls or to_decl not in store.decls:
        return "reject_unknown"
    if to_decl not in direct_references(from_decl, store):
        return "no_reference"
    if store.decls[from_decl].source_idx >= store.decls[to_decl].source_idx:
        return "source_ok"
    for grp in mutual_recursion_groups(store):
        if from_decl in grp and to_decl in grp:
            return "accepted_mutual"
    order = prerequisite_order(store)
    if order is not None:
        pos_from, pos_to = order.index(from_decl), order.index(to_decl)
        if pos_to < pos_from:
            return "accepted_linear"
    return "reject_incompatible"

def reference_closure(name: str, store: EmissionStore) -> list[str]:
    if name not in store.decls:
        raise KeyError(name)
    return _prereq_walk(store, name)
