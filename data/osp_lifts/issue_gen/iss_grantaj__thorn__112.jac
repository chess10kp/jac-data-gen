"""grantaj/thorn#112 — dependency-aware review freshness and invalidation cone."""

glob STATE_NEVER = "never_reviewed";
glob STATE_CURRENT = "current";
glob STATE_REUSED = "reused";
glob STATE_LOCAL = "locally_changed";
glob STATE_UPSTREAM = "upstream_invalidated";

node ProofUnit {
    has uid: str;
}

edge ProofDep {}

walker ReachProofWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with ProofUnit entry {
        if here.uid in self.claimed { skip; }
        self.claimed[here.uid] = True;
        self.order.append(here.uid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: ProofUnit) -> list[ProofUnit] {
    kids: list[ProofUnit] = [];
    for ch in [nd ->:ProofDep:->][?:ProofUnit] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.uid); }
    names = sorted(names);
    ordered: list[ProofUnit] = [];
    for nm in names { for ch in kids { if ch.uid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_unit(uid: str, store: dict) -> ProofUnit | None {
    nmap = store["nodes"] as dict[str, ProofUnit];
    if uid in nmap { return nmap[uid]; }
    return None;
}

def fresh_proof_store() -> dict {
    return {"units": {}, "deps": {}, "rev": {}, "nodes": {}, "records": {}, "cones": {}};
}

def register_proof_unit(unit_id: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_proof_store(); }
    (s["units"] as dict[str, bool])[unit_id] = True;
    deps = s["deps"] as dict[str, list[str]];
    if unit_id not in deps { deps[unit_id] = []; }
    rev = s["rev"] as dict[str, list[str]];
    if unit_id not in rev { rev[unit_id] = []; }
    recs = s["records"] as dict[str, dict];
    if unit_id not in recs { recs[unit_id] = {"state": STATE_NEVER, "reason": ""}; }
    nd = ProofUnit(uid=unit_id);
    root ++> nd;
    (s["nodes"] as dict[str, ProofUnit])[unit_id] = nd;
    return s;
}

def add_proof_dep(source_id: str, target_id: str, store: dict) {
    umap = store["units"] as dict[str, bool];
    if source_id not in umap or target_id not in umap { raise KeyError("unknown proof unit id"); }
    if source_id == target_id { return; }
    src_nd = _find_unit(source_id, store);
    tgt_nd = _find_unit(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:ProofDep:->][?:ProofUnit] { if ex.uid == target_id { seen = True; } }
        if not seen { src_nd +>:ProofDep:+> tgt_nd; }
    }
    outs = store["deps"] as dict[str, list[str]];
    if source_id not in outs { outs[source_id] = []; }
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if target_id not in revs { revs[target_id] = []; }
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
}

def direct_downstream(unit_id: str, store: dict) -> list[str] {
    if unit_id not in (store["units"] as dict) { raise KeyError(unit_id); }
    return list((store["deps"] as dict[str, list[str]]).get(unit_id, []));
}

def reachable_units(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["units"] as dict) { raise KeyError(start_id); }
    start_nd = _find_unit(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachProofWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for uid in w.order { if uid != start_id { reach.append(uid); } }
    return reach;
}

def attach_review_record(unit_id: str, state: str, reason: str, store: dict) {
    if unit_id not in (store["units"] as dict) { raise KeyError(unit_id); }
    recs = store["records"] as dict[str, dict];
    recs[unit_id] = {"state": state, "reason": reason};
}

def record_invalidation_cone(origin_id: str, affected_ids: list[str], store: dict) {
    if origin_id not in (store["units"] as dict) { raise KeyError(origin_id); }
    umap = store["units"] as dict[str, bool];
    for aid in affected_ids { if aid not in umap { raise KeyError(aid); } }
    cones = store["cones"] as dict[str, list[str]];
    cones[origin_id] = sorted(affected_ids);
}

def invalidation_cone(origin_id: str, store: dict) -> list[str] {
    if origin_id not in (store["units"] as dict) { raise KeyError(origin_id); }
    return list((store["cones"] as dict[str, list[str]]).get(origin_id, []));
}

def freshness_report(unit_id: str, store: dict) -> dict {
    if unit_id not in (store["units"] as dict) { raise KeyError(unit_id); }
    rec = (store["records"] as dict[str, dict]).get(unit_id, {"state": STATE_NEVER, "reason": ""});
    reach = reachable_units(unit_id, store);
    direct = direct_downstream(unit_id, store);
    cone = invalidation_cone(unit_id, store);
    return {"state": rec["state"], "reason": rec["reason"], "direct": direct, "reach": reach, "cone": cone, "reach_count": len(reach)};
}
