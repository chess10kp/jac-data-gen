"""jessealama/thales#144 — out-of-order tolerant top-level declaration emission."""

glob KIND_DEF = "def";
glob KIND_STRUCT = "structure";

node Decl {
    has name: str;
    has kind: str;
    has source_idx: int;
}

edge Refs {}

obj EmissionStore {
    has decls: dict[str, Decl] = {};
}

walker PrereqWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Decl entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [<-:Refs:<-][?:Decl];
    }
}

walker DependentWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Decl entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Refs:->][?:Decl];
    }
}

def fresh_emission_store() -> EmissionStore {
    return EmissionStore();
}

def register_declaration(name: str, kind: str, source_idx: int, store: EmissionStore | None = None) -> EmissionStore {
    s = store;
    if s is None { s = fresh_emission_store(); }
    if name in s.decls { raise ValueError("duplicate declaration"); }
    nd = Decl(name=name, kind=kind, source_idx=source_idx);
    root ++> nd;
    s.decls[name] = nd;
    return s;
}

def add_reference(from_decl: str, to_decl: str, store: EmissionStore) {
    if from_decl not in store.decls or to_decl not in store.decls { raise KeyError("unknown declaration"); }
    src = store.decls[from_decl];
    dst = store.decls[to_decl];
    seen = False;
    for ex in [dst ->:Refs:->][?:Decl] {
        if ex.name == from_decl { seen = True; }
    }
    if not seen { dst +>:Refs:+> src; }
}

def direct_references(name: str, store: EmissionStore) -> list[str] {
    if name not in store.decls { raise KeyError(name); }
    nd = store.decls[name];
    out: list[str] = [];
    for pre in [nd <-:Refs:<-][?:Decl] { out.append(pre.name); }
    return sorted(out);
}

def _prereq_walk(store: EmissionStore, start_id: str) -> list[str] {
    nd = store.decls.get(start_id, None);
    if nd is None { return []; }
    w = nd spawn PrereqWalk(claimed={}, reached=[]);
    return w.reached;
}

def _dependent_walk(store: EmissionStore, start_id: str) -> list[str] {
    nd = store.decls.get(start_id, None);
    if nd is None { return []; }
    w = nd spawn DependentWalk(claimed={}, reached=[]);
    return w.reached;
}

def mutual_recursion_groups(store: EmissionStore) -> list[list[str]] {
    assigned: dict[str, bool] = {};
    groups: list[list[str]] = [];
    for n in sorted(store.decls.keys()) {
        if n in assigned { continue; }
        fwd = _dependent_walk(store, n);
        rev = _prereq_walk(store, n);
        rev_set: dict[str, bool] = {};
        for r in rev { rev_set[r] = True; }
        comp: list[str] = [];
        for m in fwd {
            if rev_set.get(m, False) {
                comp.append(m);
                assigned[m] = True;
            }
        }
        if len(comp) > 1 { groups.append(sorted(comp)); }
    }
    for i in range(len(groups)) {
        for j in range(i + 1, len(groups)) {
            if groups[i][0] > groups[j][0] {
                tmp = groups[i];
                groups[i] = groups[j];
                groups[j] = tmp;
            }
        }
    }
    return groups;
}

def prerequisite_order(store: EmissionStore) -> list[str] | None {
    indeg: dict[str, int] = {};
    for nm in store.decls {
        indeg[nm] = len([store.decls[nm] <-:Refs:<-]);
    }
    order: list[str] = [];
    total = len(indeg);
    while len(order) < total {
        picked: list[str] = [];
        for nm in sorted(indeg.keys()) {
            if indeg[nm] == 0 { picked.append(nm); }
        }
        if len(picked) == 0 { return None; }
        for nid in picked {
            order.append(nid);
            nd = store.decls[nid];
            for succ in [nd ->:Refs:->][?:Decl] {
                indeg[succ.name] = indeg[succ.name] - 1;
            }
            indeg[nid] = -1;
        }
    }
    return order;
}

def hybrid_emit_plan(store: EmissionStore) -> dict {
    order = prerequisite_order(store);
    mutual = mutual_recursion_groups(store);
    mutual_members: dict[str, bool] = {};
    for grp in mutual {
        for m in grp { mutual_members[m] = True; }
    }
    structs: list[str] = [];
    linear_defs: list[str] = [];
    if order is not None {
        for nm in order {
            kind = store.decls[nm].kind;
            if kind == KIND_STRUCT { structs.append(nm); }
            elif kind == KIND_DEF and not mutual_members.get(nm, False) { linear_defs.append(nm); }
        }
    }
    return {"structures": structs, "linear_defs": linear_defs, "mutual_groups": mutual};
}

def classify_forward_reference(from_decl: str, to_decl: str, store: EmissionStore) -> str {
    if from_decl not in store.decls or to_decl not in store.decls { return "reject_unknown"; }
    refs = direct_references(from_decl, store);
    if to_decl not in refs { return "no_reference"; }
    if store.decls[from_decl].source_idx >= store.decls[to_decl].source_idx { return "source_ok"; }
    for grp in mutual_recursion_groups(store) {
        if from_decl in grp and to_decl in grp { return "accepted_mutual"; }
    }
    order = prerequisite_order(store);
    if order is not None {
        pos_from = -1;
        pos_to = -1;
        for i in range(len(order)) {
            if order[i] == from_decl { pos_from = i; }
            if order[i] == to_decl { pos_to = i; }
        }
        if pos_to < pos_from { return "accepted_linear"; }
    }
    return "reject_incompatible";
}

def reference_closure(name: str, store: EmissionStore) -> list[str] {
    if name not in store.decls { raise KeyError(name); }
    return _prereq_walk(store, name);
}

test "acyclic forward reference accepted by topo" {
    s = fresh_emission_store();
    register_declaration("g", KIND_DEF, 1, s);
    register_declaration("f", KIND_DEF, 0, s);
    add_reference("f", "g", s);
    assert prerequisite_order(s) == ["g", "f"];
    assert classify_forward_reference("f", "g", s) == "accepted_linear";
}

test "diamond closure skips revisit" {
    s = fresh_emission_store();
    register_declaration("hub", KIND_DEF, 0, s);
    register_declaration("left", KIND_DEF, 1, s);
    register_declaration("right", KIND_DEF, 2, s);
    register_declaration("sink", KIND_DEF, 3, s);
    add_reference("left", "sink", s);
    add_reference("right", "sink", s);
    add_reference("hub", "right", s);
    add_reference("hub", "left", s);
    assert sorted(reference_closure("hub", s)) == ["hub", "left", "right", "sink"];
}

test "mutual recursion grouped for hybrid emit" {
    s = fresh_emission_store();
    register_declaration("f", KIND_DEF, 0, s);
    register_declaration("g", KIND_DEF, 1, s);
    add_reference("f", "g", s);
    add_reference("g", "f", s);
    assert mutual_recursion_groups(s) == [["f", "g"]];
    assert classify_forward_reference("f", "g", s) == "accepted_mutual";
    plan = hybrid_emit_plan(s);
    assert plan["linear_defs"] == [];
    assert plan["mutual_groups"] == [["f", "g"]];
}

test "unknown declaration tolerance" {
    s = fresh_emission_store();
    register_declaration("a", KIND_DEF, 0, s);
    assert classify_forward_reference("ghost", "a", s) == "reject_unknown";
    caught = False;
    try {
        direct_references("ghost", s);
    } except KeyError {
        caught = True;
    }
    assert caught;
}

test "hybrid plan structures before defs" {
    s = fresh_emission_store();
    register_declaration("scale", KIND_DEF, 0, s);
    register_declaration("Point", KIND_STRUCT, 1, s);
    add_reference("scale", "Point", s);
    plan = hybrid_emit_plan(s);
    assert plan["structures"] == ["Point"];
    assert plan["linear_defs"] == ["scale"];
    assert classify_forward_reference("scale", "Point", s) == "accepted_linear";
}
