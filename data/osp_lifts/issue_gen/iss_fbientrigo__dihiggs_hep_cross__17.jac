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
