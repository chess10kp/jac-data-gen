"""ist-h-i/agent-spectrum-kernel#275 — epic admission and work-package execution topology."""

glob ADMIT_ORDINARY = "ordinary";
glob ADMIT_EPIC = "epic";
glob CHECKPOINT_OK = "ok";
glob CHECKPOINT_ROLLOVER = "rollover";

node WorkPkg {
    has wp_id: str;
    has tokens: int = 0;
}

edge PkgDep {}

walker PkgReachWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with WorkPkg entry {
        if here.wp_id in self.claimed { skip; }
        self.claimed[here.wp_id] = True;
        self.order.append(here.wp_id);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: WorkPkg) -> list[WorkPkg] {
    kids: list[WorkPkg] = [];
    for ch in [nd ->:PkgDep:->][?:WorkPkg] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.wp_id); }
    names = sorted(names);
    ordered: list[WorkPkg] = [];
    for nm in names { for ch in kids { if ch.wp_id == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_pkg(wp_id: str, store: dict) -> WorkPkg | None {
    nmap = store["nodes"] as dict[str, WorkPkg];
    if wp_id in nmap { return nmap[wp_id]; }
    return None;
}

def fresh_epic_store() -> dict {
    return {"packages": {}, "tokens": {}, "deps": {}, "rev": {}, "nodes": {}, "roots": []};
}

def register_package(wp_id: str, tokens: int, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_epic_store(); }
    (s["packages"] as dict[str, bool])[wp_id] = True;
    (s["tokens"] as dict[str, int])[wp_id] = tokens;
    outs = s["deps"] as dict[str, list[str]];
    if wp_id not in outs { outs[wp_id] = []; }
    revs = s["rev"] as dict[str, list[str]];
    if wp_id not in revs { revs[wp_id] = []; }
    nd = WorkPkg(wp_id=wp_id, tokens=tokens);
    root ++> nd;
    roots = s["roots"] as list[str];
    roots.append(wp_id);
    (s["nodes"] as dict[str, WorkPkg])[wp_id] = nd;
    return s;
}

def add_pkg_dep(source_id: str, target_id: str, store: dict) {
    pmap = store["packages"] as dict[str, bool];
    if source_id not in pmap or target_id not in pmap { raise KeyError("unknown package id"); }
    if source_id == target_id { return; }
    src_nd = _find_pkg(source_id, store);
    tgt_nd = _find_pkg(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:PkgDep:->][?:WorkPkg] { if ex.wp_id == target_id { seen = True; } }
        if not seen { src_nd +>:PkgDep:+> tgt_nd; }
        roots = store["roots"] as list[str];
        if target_id in roots { roots.remove(target_id); }
    }
    outs = store["deps"] as dict[str, list[str]];
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
}

def direct_deps(wp_id: str, store: dict) -> list[str] {
    if wp_id not in (store["packages"] as dict) { raise KeyError(wp_id); }
    return list((store["deps"] as dict[str, list[str]]).get(wp_id, []));
}

def execution_topology(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["packages"] as dict) { raise KeyError(start_id); }
    start_nd = _find_pkg(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn PkgReachWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for pid in w.order { if pid != start_id { reach.append(pid); } }
    reach = sorted(reach);
    return reach;
}

def admit_epic(store: dict, token_threshold: int) -> str {
    total = 0;
    for pid in (store["packages"] as dict).keys() { total += (store["tokens"] as dict[str, int]).get(pid, 0); }
    if total > token_threshold { return ADMIT_EPIC; }
    return ADMIT_ORDINARY;
}

def checkpoint_status(active_tokens: int, context_threshold: int) -> str {
    if active_tokens >= context_threshold { return CHECKPOINT_ROLLOVER; }
    return CHECKPOINT_OK;
}

def epic_report(start_id: str, store: dict, token_threshold: int, context_threshold: int, active_tokens: int) -> dict {
    if start_id not in (store["packages"] as dict) { raise KeyError(start_id); }
    topo = execution_topology(start_id, store);
    direct = direct_deps(start_id, store);
    admission = admit_epic(store, token_threshold);
    checkpoint = checkpoint_status(active_tokens, context_threshold);
    return {"admission": admission, "checkpoint": checkpoint, "direct": direct, "topology": topo, "topology_count": len(topo)};
}
