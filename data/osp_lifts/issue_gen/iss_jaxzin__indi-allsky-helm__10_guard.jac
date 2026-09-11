"""jaxzin/indi-allsky-helm#10 — chart release workflow DAG and GitOps reach topology."""

glob KIND_WORKFLOW = "workflow";
glob KIND_DOCS = "docs";
glob KIND_EXAMPLE = "example";
glob KIND_GATE = "gate";
glob STATUS_BLOCKED = "blocked";
glob STATUS_READY = "ready";

node ReleaseTask {
    has tid: str;
    has kind: str = "";
}

edge TaskDep {}

walker ReleaseReachWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with ReleaseTask entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: ReleaseTask) -> list[ReleaseTask] {
    kids: list[ReleaseTask] = [];
    for ch in [nd ->:TaskDep:->][?:ReleaseTask] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.tid); }
    names = sorted(names);
    ordered: list[ReleaseTask] = [];
    for nm in names { for ch in kids { if ch.tid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_task(tid: str, store: dict) -> ReleaseTask | None {
    nmap = store["nodes"] as dict[str, ReleaseTask];
    if tid in nmap { return nmap[tid]; }
    return None;
}

def fresh_release_store() -> dict {
    return {"tasks": {}, "kinds": {}, "deps": {}, "rev": {}, "nodes": {}, "roots": []};
}

def register_task(tid: str, kind: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_release_store(); }
    (s["tasks"] as dict[str, bool])[tid] = True;
    (s["kinds"] as dict[str, str])[tid] = kind;
    outs = s["deps"] as dict[str, list[str]];
    if tid not in outs { outs[tid] = []; }
    revs = s["rev"] as dict[str, list[str]];
    if tid not in revs { revs[tid] = []; }
    nd = ReleaseTask(tid=tid, kind=kind);
    root ++> nd;
    roots = s["roots"] as list[str];
    roots.append(tid);
    (s["nodes"] as dict[str, ReleaseTask])[tid] = nd;
    return s;
}

def add_task_dep(source_id: str, target_id: str, store: dict) {
    tmap = store["tasks"] as dict[str, bool];
    if source_id not in tmap or target_id not in tmap { raise KeyError("unknown task id"); }
    if source_id == target_id { return; }
    src_nd = _find_task(source_id, store);
    tgt_nd = _find_task(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:TaskDep:->][?:ReleaseTask] { if ex.tid == target_id { seen = True; } }
        if not seen { src_nd +>:TaskDep:+> tgt_nd; }
        roots = store["roots"] as list[str];
        if target_id in roots { roots.remove(target_id); }
    }
    outs = store["deps"] as dict[str, list[str]];
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
}

def direct_deps(task_id: str, store: dict) -> list[str] {
    if task_id not in (store["tasks"] as dict) { raise KeyError(task_id); }
    return list((store["deps"] as dict[str, list[str]]).get(task_id, []));
}

def release_topology(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["tasks"] as dict) { raise KeyError(start_id); }
    start_nd = _find_task(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReleaseReachWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for tid in w.order { if tid != start_id { reach.append(tid); } }
    reach = sorted(reach);
    return reach;
}

def chart_gate_status(open_blockers: int) -> str {
    if open_blockers > 0 { return STATUS_BLOCKED; }
    return STATUS_READY;
}

def release_report(start_id: str, store: dict, open_blockers: int) -> dict {
    if start_id not in (store["tasks"] as dict) { raise KeyError(start_id); }
    topo = release_topology(start_id, store);
    direct = direct_deps(start_id, store);
    gate = chart_gate_status(open_blockers);
    kinds = store["kinds"] as dict[str, str];
    wf = 0; doc = 0; ex = 0; gt = 0;
    for tid in topo {
        k = kinds.get(tid, "");
        if k == KIND_WORKFLOW { wf += 1; }
        if k == KIND_DOCS { doc += 1; }
        if k == KIND_EXAMPLE { ex += 1; }
        if k == KIND_GATE { gt += 1; }
    }
    return {"gate": gate, "direct": direct, "topology": topo, "topology_count": len(topo), "workflow_tasks": wf, "docs_tasks": doc, "example_tasks": ex, "gate_tasks": gt};
}

test "diamond revisit keeps single shared oci publish slice" {
    s = fresh_release_store();
    register_task("chart_release", KIND_WORKFLOW, s);
    register_task("release_yml", KIND_WORKFLOW, s);
    register_task("docs_bundle", KIND_DOCS, s);
    register_task("examples_bundle", KIND_EXAMPLE, s);
    register_task("oci_publish", KIND_WORKFLOW, s);
    add_task_dep("chart_release", "release_yml", s);
    add_task_dep("chart_release", "docs_bundle", s);
    add_task_dep("chart_release", "examples_bundle", s);
    add_task_dep("release_yml", "oci_publish", s);
    add_task_dep("docs_bundle", "oci_publish", s);
    add_task_dep("examples_bundle", "oci_publish", s);
    got = release_topology("chart_release", s);
    assert got == ["docs_bundle", "examples_bundle", "oci_publish", "release_yml"];
    oc = 0;
    for tid in got { if tid == "oci_publish" { oc += 1; } }
    assert oc == 1;
}

test "adversarial edge insertion order is stable" {
    s1 = fresh_release_store();
    register_task("chart_release", KIND_WORKFLOW, s1);
    register_task("docs_bundle", KIND_DOCS, s1);
    register_task("examples_bundle", KIND_EXAMPLE, s1);
    register_task("oci_publish", KIND_WORKFLOW, s1);
    add_task_dep("chart_release", "examples_bundle", s1);
    add_task_dep("examples_bundle", "oci_publish", s1);
    add_task_dep("chart_release", "docs_bundle", s1);
    add_task_dep("docs_bundle", "oci_publish", s1);
    s2 = fresh_release_store();
    register_task("chart_release", KIND_WORKFLOW, s2);
    register_task("docs_bundle", KIND_DOCS, s2);
    register_task("examples_bundle", KIND_EXAMPLE, s2);
    register_task("oci_publish", KIND_WORKFLOW, s2);
    add_task_dep("chart_release", "docs_bundle", s2);
    add_task_dep("docs_bundle", "oci_publish", s2);
    add_task_dep("chart_release", "examples_bundle", s2);
    add_task_dep("examples_bundle", "oci_publish", s2);
    assert release_topology("chart_release", s1) == release_topology("chart_release", s2);
}

test "unknown task ids raise KeyError" {
    s = fresh_release_store();
    register_task("chart_release", KIND_WORKFLOW, s);
    caught = False;
    try { add_task_dep("chart_release", "missing", s); } except KeyError { caught = True; }
    assert caught;
    caught2 = False;
    try { direct_deps("missing", s); } except KeyError { caught2 = True; }
    assert caught2;
}

test "release report tracks workflow docs and gate posture" {
    s = fresh_release_store();
    register_task("chart_release", KIND_WORKFLOW, s);
    register_task("a9_e2e", KIND_GATE, s);
    register_task("release_yml", KIND_WORKFLOW, s);
    register_task("readme", KIND_DOCS, s);
    add_task_dep("chart_release", "a9_e2e", s);
    add_task_dep("a9_e2e", "release_yml", s);
    add_task_dep("release_yml", "readme", s);
    rep = release_report("chart_release", s, 1);
    assert rep["gate"] == STATUS_BLOCKED;
    assert rep["direct"] == ["a9_e2e"];
    assert rep["topology"] == ["a9_e2e", "readme", "release_yml"];
    assert rep["workflow_tasks"] == 1;
    assert rep["docs_tasks"] == 1;
    assert rep["gate_tasks"] == 1;
    rep2 = release_report("chart_release", s, 0);
    assert rep2["gate"] == STATUS_READY;
}

test "independent release roots stay separate in topology" {
    s = fresh_release_store();
    register_task("chart_release", KIND_WORKFLOW, s);
    register_task("branch_rules", KIND_GATE, s);
    register_task("readme", KIND_DOCS, s);
    add_task_dep("chart_release", "readme", s);
    got = release_topology("branch_rules", s);
    assert got == [];
    rep = release_report("chart_release", s, 0);
    assert rep["gate_tasks"] == 0;
    assert rep["topology"] == ["readme"];
}
