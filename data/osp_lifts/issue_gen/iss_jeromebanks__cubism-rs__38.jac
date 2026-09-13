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
