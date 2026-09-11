"""fleetdm/fleet#42933 — workflow cache invalidation reach for clean CVE rebuild."""

glob RUN_MODE_CLEAN = "clean";
glob RUN_MODE_INCREMENTAL = "incremental";

node WfStage {
    has sid: str;
}

edge WfDep {}

walker ReachWfWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with WfStage entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.order.append(here.sid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: WfStage) -> list[WfStage] {
    kids: list[WfStage] = [];
    for ch in [nd ->:WfDep:->][?:WfStage] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.sid); }
    names = sorted(names);
    ordered: list[WfStage] = [];
    for nm in names { for ch in kids { if ch.sid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_stage(sid: str, store: dict) -> WfStage | None {
    nmap = store["nodes"] as dict[str, WfStage];
    if sid in nmap { return nmap[sid]; }
    return None;
}

def fresh_workflow_store() -> dict { return {"stages": {}, "deps": {}, "rev": {}, "nodes": {}, "dirty": {}}; }

def register_stage(stage_id: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_workflow_store(); }
    (s["stages"] as dict[str, bool])[stage_id] = True;
    deps = s["deps"] as dict[str, list[str]];
    if stage_id not in deps { deps[stage_id] = []; }
    rev = s["rev"] as dict[str, list[str]];
    if stage_id not in rev { rev[stage_id] = []; }
    dirty = s["dirty"] as dict[str, bool];
    dirty[stage_id] = False;
    nd = WfStage(sid=stage_id);
    root ++> nd;
    (s["nodes"] as dict[str, WfStage])[stage_id] = nd;
    return s;
}

def add_stage_edge(source_id: str, target_id: str, store: dict) {
    smap = store["stages"] as dict[str, bool];
    if source_id not in smap or target_id not in smap { raise KeyError("unknown stage id"); }
    if source_id == target_id { return; }
    src_nd = _find_stage(source_id, store);
    tgt_nd = _find_stage(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:WfDep:->][?:WfStage] { if ex.sid == target_id { seen = True; } }
        if not seen { src_nd +>:WfDep:+> tgt_nd; }
    }
    outs = store["deps"] as dict[str, list[str]];
    if source_id not in outs { outs[source_id] = []; }
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if target_id not in revs { revs[target_id] = []; }
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
}

def direct_downstream(stage_id: str, store: dict) -> list[str] {
    if stage_id not in (store["stages"] as dict) { raise KeyError(stage_id); }
    return list((store["deps"] as dict[str, list[str]]).get(stage_id, []));
}

def reachable_stages(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["stages"] as dict) { raise KeyError(start_id); }
    start_nd = _find_stage(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachWfWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for sid in w.order { if sid != start_id { reach.append(sid); } }
    return reach;
}

def invalidate_downstream(stage_id: str, store: dict) -> list[str] {
    if stage_id not in (store["stages"] as dict) { raise KeyError(stage_id); }
    reach = reachable_stages(stage_id, store);
    dirty = store["dirty"] as dict[str, bool];
    dirty[stage_id] = True;
    for sid in reach { dirty[sid] = True; }
    marked: list[str] = [stage_id];
    for sid in reach { marked.append(sid); }
    marked = sorted(marked);
    return marked;
}

def rebuild_report(stage_id: str, store: dict, force_clean: bool = False) -> dict {
    if stage_id not in (store["stages"] as dict) { raise KeyError(stage_id); }
    reach = reachable_stages(stage_id, store);
    direct = direct_downstream(stage_id, store);
    dirty = store["dirty"] as dict[str, bool];
    needs_clean = force_clean or dirty.get(stage_id, False);
    mode = RUN_MODE_CLEAN if needs_clean else RUN_MODE_INCREMENTAL;
    return {"direct": direct, "reach": reach, "reach_count": len(reach), "run_mode": mode, "force_clean": force_clean};
}
