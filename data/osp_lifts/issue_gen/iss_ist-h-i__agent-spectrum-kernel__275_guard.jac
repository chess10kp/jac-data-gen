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

test "diamond revisit keeps single shared integration slice" {
    s = fresh_epic_store();
    register_package("epic", 100, s);
    register_package("slice_a", 50, s);
    register_package("slice_b", 50, s);
    register_package("integrate", 25, s);
    add_pkg_dep("epic", "slice_a", s);
    add_pkg_dep("epic", "slice_b", s);
    add_pkg_dep("slice_a", "integrate", s);
    add_pkg_dep("slice_b", "integrate", s);
    got = execution_topology("epic", s);
    assert got == ["integrate", "slice_a", "slice_b"];
    ig = 0;
    for pid in got { if pid == "integrate" { ig += 1; } }
    assert ig == 1;
}

test "adversarial edge insertion order is stable" {
    s1 = fresh_epic_store();
    register_package("epic", 10, s1);
    register_package("slice_a", 5, s1);
    register_package("slice_b", 5, s1);
    register_package("integrate", 3, s1);
    add_pkg_dep("epic", "slice_b", s1);
    add_pkg_dep("slice_b", "integrate", s1);
    add_pkg_dep("epic", "slice_a", s1);
    add_pkg_dep("slice_a", "integrate", s1);
    s2 = fresh_epic_store();
    register_package("epic", 10, s2);
    register_package("slice_a", 5, s2);
    register_package("slice_b", 5, s2);
    register_package("integrate", 3, s2);
    add_pkg_dep("epic", "slice_a", s2);
    add_pkg_dep("slice_a", "integrate", s2);
    add_pkg_dep("epic", "slice_b", s2);
    add_pkg_dep("slice_b", "integrate", s2);
    assert execution_topology("epic", s1) == execution_topology("epic", s2);
}

test "unknown package ids raise KeyError" {
    s = fresh_epic_store();
    register_package("epic", 10, s);
    caught = False;
    try { add_pkg_dep("epic", "missing", s); } except KeyError { caught = True; }
    assert caught;
    caught2 = False;
    try { direct_deps("missing", s); } except KeyError { caught2 = True; }
    assert caught2;
}

test "epic admission triggers above token threshold" {
    s = fresh_epic_store();
    register_package("epic", 100, s);
    register_package("slice_a", 200, s);
    register_package("slice_b", 150, s);
    assert admit_epic(s, 300) == ADMIT_EPIC;
    assert admit_epic(s, 500) == ADMIT_ORDINARY;
}

test "context rollover checkpoint at pressure boundary" {
    s = fresh_epic_store();
    register_package("epic", 100, s);
    register_package("slice_a", 50, s);
    add_pkg_dep("epic", "slice_a", s);
    assert checkpoint_status(999, 1000) == CHECKPOINT_OK;
    assert checkpoint_status(1000, 1000) == CHECKPOINT_ROLLOVER;
    rep = epic_report("epic", s, 300, 1000, 1000);
    assert rep["admission"] == ADMIT_ORDINARY;
    assert rep["checkpoint"] == CHECKPOINT_ROLLOVER;
    assert rep["topology"] == ["slice_a"];
}
