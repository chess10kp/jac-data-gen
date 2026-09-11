"""huyhandes/groxpi#44 — groxpi module dependency flow reachability mapping."""

glob KIND_REQUEST = "request";
glob KIND_SYNC = "sync";

node GroModule {
    has mid: str;
    has kind: str = "";
}

edge ModDep {}

walker FlowReachWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GroModule entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.order.append(here.mid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: GroModule) -> list[GroModule] {
    kids: list[GroModule] = [];
    for ch in [nd ->:ModDep:->][?:GroModule] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.mid); }
    names = sorted(names);
    ordered: list[GroModule] = [];
    for nm in names { for ch in kids { if ch.mid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_module(mid: str, store: dict) -> GroModule | None {
    nmap = store["nodes"] as dict[str, GroModule];
    if mid in nmap { return nmap[mid]; }
    return None;
}

def fresh_module_store() -> dict {
    return {"modules": {}, "kinds": {}, "deps": {}, "rev": {}, "nodes": {}, "roots": []};
}

def register_module(mid: str, kind: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_module_store(); }
    (s["modules"] as dict[str, bool])[mid] = True;
    (s["kinds"] as dict[str, str])[mid] = kind;
    outs = s["deps"] as dict[str, list[str]];
    if mid not in outs { outs[mid] = []; }
    revs = s["rev"] as dict[str, list[str]];
    if mid not in revs { revs[mid] = []; }
    nd = GroModule(mid=mid, kind=kind);
    root ++> nd;
    roots = s["roots"] as list[str];
    roots.append(mid);
    (s["nodes"] as dict[str, GroModule])[mid] = nd;
    return s;
}

def add_module_dep(source_id: str, target_id: str, store: dict) {
    mmap = store["modules"] as dict[str, bool];
    if source_id not in mmap or target_id not in mmap { raise KeyError("unknown module id"); }
    if source_id == target_id { return; }
    src_nd = _find_module(source_id, store);
    tgt_nd = _find_module(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:ModDep:->][?:GroModule] { if ex.mid == target_id { seen = True; } }
        if not seen { src_nd +>:ModDep:+> tgt_nd; }
        roots = store["roots"] as list[str];
        if target_id in roots { roots.remove(target_id); }
    }
    outs = store["deps"] as dict[str, list[str]];
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
}

def direct_deps(module_id: str, store: dict) -> list[str] {
    if module_id not in (store["modules"] as dict) { raise KeyError(module_id); }
    return list((store["deps"] as dict[str, list[str]]).get(module_id, []));
}

def reachable_modules(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["modules"] as dict) { raise KeyError(start_id); }
    start_nd = _find_module(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn FlowReachWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for mid in w.order { if mid != start_id { reach.append(mid); } }
    reach = sorted(reach);
    return reach;
}

def pipeline_report(start_id: str, store: dict) -> dict {
    if start_id not in (store["modules"] as dict) { raise KeyError(start_id); }
    reach = reachable_modules(start_id, store);
    direct = direct_deps(start_id, store);
    kinds = store["kinds"] as dict[str, str];
    req_count = 0;
    sync_count = 0;
    for mid in reach {
        k = kinds.get(mid, "");
        if k == KIND_REQUEST { req_count += 1; }
        if k == KIND_SYNC { sync_count += 1; }
    }
    return {"direct": direct, "reach": reach, "reach_count": len(reach), "request_modules": req_count, "sync_modules": sync_count};
}
