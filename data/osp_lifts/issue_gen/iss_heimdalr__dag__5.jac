"""heimdalr/dag#5 — DAG edge add with ancestor cache invalidation on descendants."""

node DagVertex {
    has vid: str;
}

edge DagDep {}

walker DescWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with DagVertex entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        self.order.append(here.vid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with DagVertex entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        self.order.append(here.vid);
        parents = _sorted_in(here);
        i = len(parents) - 1;
        while i >= 0 { visit :0: [parents[i]]; i -= 1; }
    }
}

def _sorted_out(nd: DagVertex) -> list[DagVertex] {
    kids: list[DagVertex] = [];
    for ch in [nd ->:DagDep:->][?:DagVertex] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.vid); }
    names = sorted(names);
    ordered: list[DagVertex] = [];
    for nm in names { for ch in kids { if ch.vid == nm { ordered.append(ch); } } }
    return ordered;
}

def _sorted_in(nd: DagVertex) -> list[DagVertex] {
    parents: list[DagVertex] = [];
    for p in [nd <-:DagDep:<-][?:DagVertex] { parents.append(p); }
    names: list[str] = [];
    for p in parents { names.append(p.vid); }
    names = sorted(names);
    ordered: list[DagVertex] = [];
    for nm in names { for p in parents { if p.vid == nm { ordered.append(p); } } }
    return ordered;
}

def _find_vertex(vid: str, store: dict) -> DagVertex | None {
    nmap = store["nodes"] as dict[str, DagVertex];
    if vid in nmap { return nmap[vid]; }
    return None;
}

def _reach_down(start_id: str, store: dict) -> list[str] {
    start_nd = _find_vertex(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn DescWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for vid in w.order { if vid != start_id { reach.append(vid); } }
    return reach;
}

def _reach_up(start_id: str, store: dict) -> list[str] {
    start_nd = _find_vertex(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn AncestorWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for vid in w.order { if vid != start_id { reach.append(vid); } }
    return reach;
}

def fresh_dag_store() -> dict {
    return {"vertices": {}, "deps": {}, "rev": {}, "nodes": {}, "ancestors_cache": {}, "descendants_cache": {}};
}

def register_vertex(vid: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_dag_store(); }
    (s["vertices"] as dict[str, bool])[vid] = True;
    outs = s["deps"] as dict[str, list[str]];
    if vid not in outs { outs[vid] = []; }
    revs = s["rev"] as dict[str, list[str]];
    if vid not in revs { revs[vid] = []; }
    nd = DagVertex(vid=vid);
    root ++> nd;
    (s["nodes"] as dict[str, DagVertex])[vid] = nd;
    return s;
}

def _has_edge(source_id: str, target_id: str, store: dict) -> bool {
    outs = store["deps"] as dict[str, list[str]];
    return target_id in outs.get(source_id, []);
}

def _invalidate_ancestor_cache(vids: list[str], store: dict) -> int {
    cache = store["ancestors_cache"] as dict[str, list[str]];
    n = 0;
    for vid in vids { if vid in cache { del cache[vid]; n += 1; } }
    return n;
}

def add_dag_edge(source_id: str, target_id: str, store: dict) {
    vmap = store["vertices"] as dict[str, bool];
    if source_id not in vmap or target_id not in vmap { raise KeyError("unknown vertex id"); }
    if _has_edge(source_id, target_id, store) { raise ValueError("duplicate edge"); }
    descendants = _reach_down(target_id, store);
    if source_id == target_id or source_id in descendants { raise ValueError("edge loop"); }
    src_nd = _find_vertex(source_id, store);
    tgt_nd = _find_vertex(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        src_nd +>:DagDep:+> tgt_nd;
    }
    outs = store["deps"] as dict[str, list[str]];
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
    inv: list[str] = [target_id];
    for vid in descendants { inv.append(vid); }
    _invalidate_ancestor_cache(inv, store);
    dcache = store["descendants_cache"] as dict[str, list[str]];
    for key in list(dcache.keys()) { del dcache[key]; }
}

def get_descendants(vid: str, store: dict) -> list[str] {
    if vid not in (store["vertices"] as dict) { raise KeyError(vid); }
    dcache = store["descendants_cache"] as dict[str, list[str]];
    if vid in dcache { return list(dcache[vid]); }
    reach = sorted(_reach_down(vid, store));
    dcache[vid] = reach;
    return list(reach);
}

def get_ancestors(vid: str, store: dict) -> list[str] {
    if vid not in (store["vertices"] as dict) { raise KeyError(vid); }
    acache = store["ancestors_cache"] as dict[str, list[str]];
    if vid in acache { return list(acache[vid]); }
    reach = sorted(_reach_up(vid, store));
    acache[vid] = reach;
    return list(reach);
}

def edge_add_report(source_id: str, target_id: str, store: dict) -> dict {
    descendants = get_descendants(target_id, store);
    ancestors = get_ancestors(source_id, store);
    return {"descendant_count": len(descendants), "ancestor_count": len(ancestors), "cache_keys": len((store["ancestors_cache"] as dict))};
}
