"""github/spec-kit-copilot#16 — inter-feature dependency stack reachability."""

node Feature {
    has fid: str;
}

edge DependsOn {}

walker ReachDependentsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Feature entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        self.order.append(here.fid);
        kids = _sorted_dependents(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_dependents(nd: Feature) -> list[Feature] {
    kids: list[Feature] = [];
    for ch in [nd ->:DependsOn:->][?:Feature] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.fid); }
    names = sorted(names);
    ordered: list[Feature] = [];
    for nm in names { for ch in kids { if ch.fid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_feature(fid: str, store: dict) -> Feature | None {
    nmap = store["nodes"] as dict[str, Feature];
    if fid in nmap { return nmap[fid]; }
    return None;
}

def fresh_stack_store() -> dict { return {"features": {}, "deps": {}, "rev": {}, "nodes": {}, "stacked": {}, "lanes": {}}; }

def register_feature(feature_id: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_stack_store(); }
    (s["features"] as dict[str, bool])[feature_id] = True;
    outs = s["deps"] as dict[str, list[str]];
    if feature_id not in outs { outs[feature_id] = []; }
    rev = s["rev"] as dict[str, list[str]];
    if feature_id not in rev { rev[feature_id] = []; }
    stacked = s["stacked"] as dict[str, bool];
    stacked[feature_id] = False;
    lanes = s["lanes"] as dict[str, int];
    lanes[feature_id] = 0;
    nd = Feature(fid=feature_id);
    root ++> nd;
    (s["nodes"] as dict[str, Feature])[feature_id] = nd;
    return s;
}

def add_dependency_edge(upstream_id: str, dependent_id: str, store: dict) {
    fmap = store["features"] as dict[str, bool];
    if upstream_id not in fmap or dependent_id not in fmap { raise KeyError("unknown feature id"); }
    if upstream_id == dependent_id { return; }
    up_nd = _find_feature(upstream_id, store);
    dep_nd = _find_feature(dependent_id, store);
    if up_nd is not None and dep_nd is not None {
        seen = False;
        for ex in [up_nd ->:DependsOn:->][?:Feature] { if ex.fid == dependent_id { seen = True; } }
        if not seen { up_nd +>:DependsOn:+> dep_nd; }
    }
    outs = store["deps"] as dict[str, list[str]];
    if upstream_id not in outs { outs[upstream_id] = []; }
    if dependent_id not in outs[upstream_id] {
        outs[upstream_id].append(dependent_id);
        outs[upstream_id] = sorted(outs[upstream_id]);
    }
    revs = store["rev"] as dict[str, list[str]];
    if dependent_id not in revs { revs[dependent_id] = []; }
    if upstream_id not in revs[dependent_id] {
        revs[dependent_id].append(upstream_id);
        revs[dependent_id] = sorted(revs[dependent_id]);
    }
}

def direct_dependents(upstream_id: str, store: dict) -> list[str] {
    if upstream_id not in (store["features"] as dict) { raise KeyError(upstream_id); }
    return list((store["deps"] as dict[str, list[str]]).get(upstream_id, []));
}

def reachable_dependents(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["features"] as dict) { raise KeyError(start_id); }
    start_nd = _find_feature(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachDependentsWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for fid in w.order { if fid != start_id { reach.append(fid); } }
    return reach;
}

def cascade_mark_stacked(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["features"] as dict) { raise KeyError(start_id); }
    reach = reachable_dependents(start_id, store);
    stacked = store["stacked"] as dict[str, bool];
    lanes = store["lanes"] as dict[str, int];
    marked: list[str] = [start_id];
    stacked[start_id] = True;
    lanes[start_id] = 1;
    layer = 2;
    for fid in reach {
        stacked[fid] = True;
        lanes[fid] = layer;
        layer += 1;
        marked.append(fid);
    }
    return sorted(marked);
}

def stack_report(feature_id: str, store: dict) -> dict {
    if feature_id not in (store["features"] as dict) { raise KeyError(feature_id); }
    reach = reachable_dependents(feature_id, store);
    direct = direct_dependents(feature_id, store);
    stacked = store["stacked"] as dict[str, bool];
    stack_count = 0;
    for fid in reach { if stacked.get(fid, False) { stack_count += 1; } }
    if stacked.get(feature_id, False) { stack_count += 1; }
    return {"direct": direct, "reach": reach, "reach_count": len(reach), "stacked": stacked.get(feature_id, False), "stack_layer_count": stack_count};
}

test "diamond revisit keeps single shared dependent" {
    s = fresh_stack_store();
    register_feature("4210", s);
    register_feature("feat_a", s);
    register_feature("feat_b", s);
    register_feature("shared", s);
    add_dependency_edge("4210", "feat_a", s);
    add_dependency_edge("4210", "feat_b", s);
    add_dependency_edge("feat_a", "shared", s);
    add_dependency_edge("feat_b", "shared", s);
    got = reachable_dependents("4210", s);
    assert got == ["feat_a", "shared", "feat_b"];
    s_count = 0;
    for fid in got { if fid == "shared" { s_count += 1; } }
    assert s_count == 1;
}

test "adversarial dependency insertion order is stable" {
    s1 = fresh_stack_store();
    register_feature("4210", s1);
    register_feature("feat_a", s1);
    register_feature("feat_b", s1);
    register_feature("shared", s1);
    add_dependency_edge("4210", "feat_b", s1);
    add_dependency_edge("feat_b", "shared", s1);
    add_dependency_edge("4210", "feat_a", s1);
    add_dependency_edge("feat_a", "shared", s1);
    s2 = fresh_stack_store();
    register_feature("4210", s2);
    register_feature("feat_a", s2);
    register_feature("feat_b", s2);
    register_feature("shared", s2);
    add_dependency_edge("4210", "feat_a", s2);
    add_dependency_edge("feat_a", "shared", s2);
    add_dependency_edge("4210", "feat_b", s2);
    add_dependency_edge("feat_b", "shared", s2);
    assert reachable_dependents("4210", s1) == reachable_dependents("4210", s2);
}

test "unknown feature ids raise KeyError" {
    s = fresh_stack_store();
    register_feature("4210", s);
    caught = False;
    try { direct_dependents("missing", s); } except KeyError { caught = True; }
    assert caught;
    caught2 = False;
    try { add_dependency_edge("4210", "missing", s); } except KeyError { caught2 = True; }
    assert caught2;
}

test "cascade mark stacked applies outside walk collection" {
    s = fresh_stack_store();
    register_feature("4210", s);
    register_feature("4212", s);
    add_dependency_edge("4210", "4212", s);
    marked = cascade_mark_stacked("4210", s);
    assert marked == ["4210", "4212"];
    rep = stack_report("4210", s);
    assert rep["stacked"] == True;
    assert rep["stack_layer_count"] == 2;
}

test "stack report binds direct and reach facts" {
    s = fresh_stack_store();
    register_feature("4210", s);
    register_feature("4212", s);
    add_dependency_edge("4210", "4212", s);
    rep = stack_report("4210", s);
    assert rep["direct"] == ["4212"];
    assert rep["reach"] == ["4212"];
    assert rep["reach_count"] == 1;
    assert rep["stacked"] == False;
    assert rep["stack_layer_count"] == 0;
}
