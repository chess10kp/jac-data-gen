"""eugenemalaschuk-source/arch-linter-net#516 — deterministic architecture metric semantics."""

node Component { has cid: str; }

edge ArchDep {}

walker ReachOutWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Component entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: Component) -> list[Component] {
    kids: list[Component] = [];
    for ch in [nd ->:ArchDep:->][?:Component] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.cid); }
    names = sorted(names);
    ordered: list[Component] = [];
    for nm in names { for ch in kids { if ch.cid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_component(cid: str, store: dict) -> Component | None {
    nmap = store["nodes"] as dict[str, Component];
    if cid in nmap { return nmap[cid]; }
    return None;
}

def fresh_metric_store() -> dict { return {"components": {}, "deps": {}, "rev": {}, "nodes": {}}; }

def register_component(component_id: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_metric_store(); }
    (s["components"] as dict[str, bool])[component_id] = True;
    deps = s["deps"] as dict[str, list[str]];
    if component_id not in deps { deps[component_id] = []; }
    rev = s["rev"] as dict[str, list[str]];
    if component_id not in rev { rev[component_id] = []; }
    nd = Component(cid=component_id);
    root ++> nd;
    (s["nodes"] as dict[str, Component])[component_id] = nd;
    return s;
}

def add_dependency(source_id: str, target_id: str, store: dict) {
    cmap = store["components"] as dict[str, bool];
    if source_id not in cmap or target_id not in cmap { raise KeyError("unknown component id"); }
    if source_id == target_id { return; }
    src_nd = _find_component(source_id, store);
    tgt_nd = _find_component(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:ArchDep:->][?:Component] { if ex.cid == target_id { seen = True; } }
        if not seen { src_nd +>:ArchDep:+> tgt_nd; }
    }
    outs = store["deps"] as dict[str, list[str]];
    if source_id not in outs { outs[source_id] = []; }
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if target_id not in revs { revs[target_id] = []; }
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
}

def distinct_outgoing(component_id: str, store: dict) -> list[str] {
    if component_id not in (store["components"] as dict) { raise KeyError(component_id); }
    return list((store["deps"] as dict[str, list[str]]).get(component_id, []));
}

def distinct_incoming(component_id: str, store: dict) -> list[str] {
    if component_id not in (store["components"] as dict) { raise KeyError(component_id); }
    return list((store["rev"] as dict[str, list[str]]).get(component_id, []));
}

def transitive_targets(component_id: str, store: dict) -> list[str] {
    if component_id not in (store["components"] as dict) { raise KeyError(component_id); }
    start_nd = _find_component(component_id, store);
    if start_nd is None { raise KeyError(component_id); }
    w = start_nd spawn ReachOutWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for cid in w.order { if cid != component_id { reach.append(cid); } }
    return reach;
}

def metric_report(component_id: str, store: dict) -> dict {
    out = distinct_outgoing(component_id, store);
    inc = distinct_incoming(component_id, store);
    reach = transitive_targets(component_id, store);
    return {"out_degree": len(out), "in_degree": len(inc), "reach_count": len(reach), "outgoing": out, "incoming": inc, "reach": reach};
}

test "diamond revisit keeps single shared target" {
    s = fresh_metric_store();
    register_component("A", s);
    register_component("B", s);
    register_component("C", s);
    register_component("D", s);
    add_dependency("A", "B", s);
    add_dependency("A", "C", s);
    add_dependency("B", "D", s);
    add_dependency("C", "D", s);
    got = transitive_targets("A", s);
    assert got == ["B", "D", "C"];
    d_count = 0;
    for cid in got { if cid == "D" { d_count += 1; } }
    assert d_count == 1;
}

test "adversarial dependency insertion order is stable" {
    s1 = fresh_metric_store();
    register_component("A", s1);
    register_component("B", s1);
    register_component("C", s1);
    register_component("D", s1);
    add_dependency("A", "C", s1);
    add_dependency("C", "D", s1);
    add_dependency("A", "B", s1);
    add_dependency("B", "D", s1);
    s2 = fresh_metric_store();
    register_component("A", s2);
    register_component("B", s2);
    register_component("C", s2);
    register_component("D", s2);
    add_dependency("A", "B", s2);
    add_dependency("B", "D", s2);
    add_dependency("A", "C", s2);
    add_dependency("C", "D", s2);
    assert transitive_targets("A", s1) == transitive_targets("A", s2);
}

test "unknown component ids raise KeyError" {
    s = fresh_metric_store();
    register_component("A", s);
    caught = False;
    try { distinct_outgoing("Z", s); } except KeyError { caught = True; }
    assert caught;
    caught2 = False;
    try { add_dependency("A", "Z", s); } except KeyError { caught2 = True; }
    assert caught2;
}

test "duplicate dependency does not inflate metrics" {
    s = fresh_metric_store();
    register_component("A", s);
    register_component("B", s);
    add_dependency("A", "B", s);
    add_dependency("A", "B", s);
    assert distinct_outgoing("A", s) == ["B"];
    rep = metric_report("A", s);
    assert rep["out_degree"] == 1;
    assert rep["reach_count"] == 1;
}

test "self edge is excluded from metrics" {
    s = fresh_metric_store();
    register_component("A", s);
    add_dependency("A", "A", s);
    assert distinct_outgoing("A", s) == [];
    assert transitive_targets("A", s) == [];
}
