"""fbientrigo/dihiggs_hep_cross#17 — versioned generated-event handoff lineage reach."""

node EventSample {
    has sid: str;
    has point_id: str;
}

edge Lineage {}

walker ReachLineageWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with EventSample entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.order.append(here.sid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: EventSample) -> list[EventSample] {
    kids: list[EventSample] = [];
    for ch in [nd ->:Lineage:->][?:EventSample] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.sid); }
    names = sorted(names);
    ordered: list[EventSample] = [];
    for nm in names { for ch in kids { if ch.sid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_sample(sid: str, store: dict) -> EventSample | None {
    nmap = store["nodes"] as dict[str, EventSample];
    if sid in nmap { return nmap[sid]; }
    return None;
}

def fresh_handoff_store() -> dict { return {"samples": {}, "deps": {}, "rev": {}, "nodes": {}, "points": {}}; }

def register_sample(sample_id: str, point_id: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_handoff_store(); }
    (s["samples"] as dict[str, str])[sample_id] = point_id;
    (s["points"] as dict[str, str])[point_id] = sample_id;
    deps = s["deps"] as dict[str, list[str]];
    if sample_id not in deps { deps[sample_id] = []; }
    rev = s["rev"] as dict[str, list[str]];
    if sample_id not in rev { rev[sample_id] = []; }
    nd = EventSample(sid=sample_id, point_id=point_id);
    root ++> nd;
    (s["nodes"] as dict[str, EventSample])[sample_id] = nd;
    return s;
}

def add_lineage_edge(source_id: str, target_id: str, store: dict) {
    smap = store["samples"] as dict[str, str];
    if source_id not in smap or target_id not in smap { raise KeyError("unknown sample id"); }
    if source_id == target_id { return; }
    src_nd = _find_sample(source_id, store);
    tgt_nd = _find_sample(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:Lineage:->][?:EventSample] { if ex.sid == target_id { seen = True; } }
        if not seen { src_nd +>:Lineage:+> tgt_nd; }
    }
    outs = store["deps"] as dict[str, list[str]];
    if source_id not in outs { outs[source_id] = []; }
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if target_id not in revs { revs[target_id] = []; }
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
}

def direct_downstream(sample_id: str, store: dict) -> list[str] {
    if sample_id not in (store["samples"] as dict) { raise KeyError(sample_id); }
    return list((store["deps"] as dict[str, list[str]]).get(sample_id, []));
}

def direct_upstream(sample_id: str, store: dict) -> list[str] {
    if sample_id not in (store["samples"] as dict) { raise KeyError(sample_id); }
    return list((store["rev"] as dict[str, list[str]]).get(sample_id, []));
}

def reachable_samples(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["samples"] as dict) { raise KeyError(start_id); }
    start_nd = _find_sample(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachLineageWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for sid in w.order { if sid != start_id { reach.append(sid); } }
    return reach;
}

def handoff_report(sample_id: str, store: dict) -> dict {
    if sample_id not in (store["samples"] as dict) { raise KeyError(sample_id); }
    reach = reachable_samples(sample_id, store);
    return {"point_id": (store["samples"] as dict[str, str])[sample_id], "direct": direct_downstream(sample_id, store), "reach": reach, "reach_count": len(reach)};
}

test "diamond revisit keeps single shared target" {
    s = fresh_handoff_store();
    register_sample("mg_prod", "pt_001", s);
    register_sample("pythia_decay", "pt_001", s);
    register_sample("pack_aa", "pt_001", s);
    register_sample("recast_input", "pt_001", s);
    add_lineage_edge("mg_prod", "pythia_decay", s);
    add_lineage_edge("mg_prod", "pack_aa", s);
    add_lineage_edge("pythia_decay", "recast_input", s);
    add_lineage_edge("pack_aa", "recast_input", s);
    got = reachable_samples("mg_prod", s);
    assert got == ["pack_aa", "recast_input", "pythia_decay"];
    r_count = 0;
    for sid in got { if sid == "recast_input" { r_count += 1; } }
    assert r_count == 1;
}

test "adversarial lineage insertion order is stable" {
    s1 = fresh_handoff_store();
    register_sample("mg_prod", "pt_001", s1);
    register_sample("pythia_decay", "pt_001", s1);
    register_sample("pack_aa", "pt_001", s1);
    register_sample("recast_input", "pt_001", s1);
    add_lineage_edge("mg_prod", "pack_aa", s1);
    add_lineage_edge("pack_aa", "recast_input", s1);
    add_lineage_edge("mg_prod", "pythia_decay", s1);
    add_lineage_edge("pythia_decay", "recast_input", s1);
    s2 = fresh_handoff_store();
    register_sample("mg_prod", "pt_002", s2);
    register_sample("pythia_decay", "pt_002", s2);
    register_sample("pack_aa", "pt_002", s2);
    register_sample("recast_input", "pt_002", s2);
    add_lineage_edge("mg_prod", "pythia_decay", s2);
    add_lineage_edge("pythia_decay", "recast_input", s2);
    add_lineage_edge("mg_prod", "pack_aa", s2);
    add_lineage_edge("pack_aa", "recast_input", s2);
    assert reachable_samples("mg_prod", s1) == reachable_samples("mg_prod", s2);
}

test "unknown sample ids raise KeyError" {
    s = fresh_handoff_store();
    register_sample("mg_prod", "pt_001", s);
    caught = False;
    try { direct_downstream("missing", s); } except KeyError { caught = True; }
    assert caught;
    caught2 = False;
    try { add_lineage_edge("mg_prod", "missing", s); } except KeyError { caught2 = True; }
    assert caught2;
}

test "duplicate lineage edge does not inflate reach" {
    s = fresh_handoff_store();
    register_sample("mg_prod", "pt_001", s);
    register_sample("hepmc_out", "pt_001", s);
    add_lineage_edge("mg_prod", "hepmc_out", s);
    add_lineage_edge("mg_prod", "hepmc_out", s);
    assert direct_downstream("mg_prod", s) == ["hepmc_out"];
    rep = handoff_report("mg_prod", s);
    assert rep["reach_count"] == 1;
}

test "handoff report binds point and lineage facts" {
    s = fresh_handoff_store();
    register_sample("mg_prod", "pt_042", s);
    register_sample("recast_input", "pt_042", s);
    add_lineage_edge("mg_prod", "recast_input", s);
    rep = handoff_report("mg_prod", s);
    assert rep["point_id"] == "pt_042";
    assert rep["direct"] == ["recast_input"];
    assert rep["reach"] == ["recast_input"];
    assert rep["reach_count"] == 1;
    assert direct_upstream("recast_input", s) == ["mg_prod"];
}
