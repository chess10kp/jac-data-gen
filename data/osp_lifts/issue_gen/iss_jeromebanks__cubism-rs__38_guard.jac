node Repo { has rid: str; }
node Issue { has iid: str; has kind: str; has status: str; has updated: int = 0; }
node Gate { has gid: str; has name: str; has required: bool = True; has passed: bool = False; }
node Artifact { has aid: str; has version: str; has reproducible: bool = False; }
edge Contains {}
edge Depends {}
edge Requires {}
edge Produces {}
walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Issue entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.found.append(here.iid);
        print(here.iid);
        kids: list[Issue] = [here ->:Depends:->][?:Issue];
        for k in kids {
            visit :0: [k];
        }
    }
}
def find_issue(graph_root: Repo, iid: str) -> Issue | None {
    candidates: list[Issue] = [graph_root ->:Contains:->][?:Issue];
    for c in candidates {
        if c.iid == iid {
            return c;
        }
    }
    return None;
}
def find_gate(graph_root: Repo, gid: str) -> Gate | None {
    candidates: list[Gate] = [graph_root ->:Contains:->][?:Gate];
    for c in candidates {
        if c.gid == gid {
            return c;
        }
    }
    return None;
}
def find_artifact(graph_root: Repo, aid: str) -> Artifact | None {
    candidates: list[Artifact] = [graph_root ->:Contains:->][?:Artifact];
    for c in candidates {
        if c.aid == aid {
            return c;
        }
    }
    return None;
}
def make_repo(rid: str) -> Repo {
    r = Repo(rid=rid);
    root ++> r;
    print(r.rid);
    return r;
}
def add_issue(graph_root: Repo, iid: str, kind: str) -> Issue {
    existing = find_issue(graph_root, iid);
    if existing is not None {
        return existing;
    }
    nd = Issue(iid=iid, kind=kind, status="open", updated=0);
    graph_root +>:Contains:+> nd;
    print(nd.iid);
    return nd;
}
def add_dependency(graph_root: Repo, from_iid: str, to_iid: str) -> bool {
    frm = find_issue(graph_root, from_iid);
    to = find_issue(graph_root, to_iid);
    if frm is None { return False; }
    if to is None { return False; }
    frm +>:Depends:+> to;
    return True;
}
def add_gate(graph_root: Repo, iid: str, gid: str, name: str, required: bool) -> bool {
    iss = find_issue(graph_root, iid);
    if iss is None { return False; }
    g = Gate(gid=gid, name=name, required=required, passed=False);
    graph_root +>:Contains:+> g;
    iss +>:Requires:+> g;
    print(g.gid);
    return True;
}
def set_gate_passed(graph_root: Repo, gid: str, passed: bool) -> bool {
    g = find_gate(graph_root, gid);
    if g is None { return False; }
    g.passed = passed;
    return True;
}
def add_artifact(graph_root: Repo, iid: str, aid: str, version: str) -> bool {
    iss = find_issue(graph_root, iid);
    if iss is None { return False; }
    a = Artifact(aid=aid, version=version, reproducible=False);
    graph_root +>:Contains:+> a;
    iss +>:Produces:+> a;
    print(a.aid);
    return True;
}
def get_transitive_deps(graph_root: Repo, start_iid: str) -> list[str] {
    start = find_issue(graph_root, start_iid);
    if start is None { return []; }
    w = start spawn ReachWalker(claimed={});
    res: list[str] = [];
    for fid in w.found {
        if fid != start_iid { res.append(fid); }
    }
    return sorted(res);
}
def get_blocked_issues(graph_root: Repo) -> list[str] {
    issues: list[Issue] = [graph_root ->:Contains:->][?:Issue];
    blocked: list[str] = [];
    for iss in issues {
        if iss.status == "closed" { continue; }
        deps: list[Issue] = [iss ->:Depends:->][?:Issue];
        is_blocked: bool = False;
        for d in deps {
            if d.status != "closed" { is_blocked = True; }
        }
        gates: list[Gate] = [iss ->:Requires:->][?:Gate];
        for g in gates {
            if g.required and not g.passed { is_blocked = True; }
        }
        if is_blocked { blocked.append(iss.iid); }
    }
    return sorted(blocked);
}
def trace_provenance(graph_root: Repo, aid: str) -> list[str] {
    a = find_artifact(graph_root, aid);
    if a is None { return []; }
    prov: list[str] = [];
    seen: dict[str, bool] = {};
    issues: list[Issue] = [graph_root ->:Contains:->][?:Issue];
    for iss in issues {
        outs: list[Artifact] = [iss ->:Produces:->][?:Artifact];
        for o in outs {
            if o.aid == aid {
                w = iss spawn ReachWalker(claimed={});
                for fid in w.found {
                    if fid not in seen {
                        seen[fid] = True;
                        prov.append(fid);
                    }
                }
            }
        }
    }
    return sorted(prov);
}
def reconcile_issue(graph_root: Repo, iid: str) -> str {
    iss = find_issue(graph_root, iid);
    if iss is None { return "unknown"; }
    deps: list[Issue] = [iss ->:Depends:->][?:Issue];
    for d in deps {
        if d.status != "closed" { return iss.status; }
    }
    gates: list[Gate] = [iss ->:Requires:->][?:Gate];
    for g in gates {
        if g.required and not g.passed { return iss.status; }
    }
    iss.status = "closed";
    iss.updated = iss.updated + 1;
    return iss.status;
}
with entry {
    demo: Repo = make_repo("demo");
    print("cubism sdlc ready");
}

test "diamond_revisit_adversarial_order" {
    r: Repo = make_repo("test_diamond");
    a = add_issue(r, "A", "epic");
    b = add_issue(r, "B", "bounded");
    c = add_issue(r, "C", "bounded");
    d = add_issue(r, "D", "bounded");
    assert(add_dependency(r, "A", "B") == True);
    assert(add_dependency(r, "A", "C") == True);
    assert(add_dependency(r, "B", "D") == True);
    assert(add_dependency(r, "C", "D") == True);
    deps: list[str] = get_transitive_deps(r, "A");
    assert(len(deps) == 3);
    assert(deps == sorted(deps));
    assert("B" in deps);
    assert("C" in deps);
    assert("D" in deps);
    deps2: list[str] = get_transitive_deps(r, "D");
    assert(len(deps2) == 0);
}
test "unknown_id_tolerance" {
    r: Repo = make_repo("test_unknown");
    add_issue(r, "X", "bounded");
    assert(add_dependency(r, "X", "NOPE") == False);
    assert(add_dependency(r, "NOPE", "X") == False);
    assert(add_gate(r, "NOPE", "g1", "ci", True) == False);
    assert(set_gate_passed(r, "no_gate", True) == False);
    assert(add_artifact(r, "NOPE", "art1", "0.1.0") == False);
    empty: list[str] = get_transitive_deps(r, "MISSING");
    assert(len(empty) == 0);
    assert(trace_provenance(r, "missing_art") == []);
    assert(reconcile_issue(r, "MISSING") == "unknown");
}
test "cycle_claim_map_no_loop" {
    r: Repo = make_repo("test_cycle");
    add_issue(r, "N1", "bounded");
    add_issue(r, "N2", "bounded");
    add_issue(r, "N3", "bounded");
    assert(add_dependency(r, "N1", "N2") == True);
    assert(add_dependency(r, "N2", "N3") == True);
    assert(add_dependency(r, "N3", "N1") == True);
    deps: list[str] = get_transitive_deps(r, "N1");
    assert(len(deps) == 2);
    assert("N2" in deps);
    assert("N3" in deps);
    assert("N1" not in deps);
    blocked: list[str] = get_blocked_issues(r);
    assert("N1" in blocked);
}
test "blocked_reconcile_and_provenance_lineage" {
    r: Repo = make_repo("test_block");
    epic = add_issue(r, "epic#38", "epic");
    i7 = add_issue(r, "issue#7", "bounded");
    i15 = add_issue(r, "issue#15", "bounded");
    assert(add_dependency(r, "epic#38", "issue#7") == True);
    assert(add_dependency(r, "issue#7", "issue#15") == True);
    assert(add_gate(r, "epic#38", "gate_ci", "required CI", True) == True);
    assert(add_gate(r, "epic#38", "gate_perf", "perf_regression", True) == True);
    blocked: list[str] = get_blocked_issues(r);
    assert("epic#38" in blocked);
    assert(reconcile_issue(r, "epic#38") == "open");
    assert(set_gate_passed(r, "gate_ci", True) == True);
    assert(set_gate_passed(r, "gate_perf", True) == True);
    assert(reconcile_issue(r, "epic#38") == "open");
    assert(reconcile_issue(r, "issue#15") == "closed");
    assert(reconcile_issue(r, "issue#7") == "closed");
    assert(reconcile_issue(r, "epic#38") == "closed");
    assert(add_artifact(r, "epic#38", "cubism-0.2.0", "0.2.0") == True);
    prov: list[str] = trace_provenance(r, "cubism-0.2.0");
    assert("epic#38" in prov);
    assert("issue#7" in prov);
    assert("issue#15" in prov);
    assert(prov == sorted(prov));
}
