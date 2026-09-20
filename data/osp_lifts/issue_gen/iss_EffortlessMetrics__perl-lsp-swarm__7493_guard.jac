"""EffortlessMetrics/perl-lsp-swarm#7493 — per-file semantic contributions; ProjectModel cross-file lookup."""

node File {
    has cid: str;
    has uri: str;
    has ast_hash: str;
}

node Project {
    has pid: str;
    has legacy_retired: bool = False;
}

edge Depends {}

obj SemanticWorkspace {
    has graph_root: File | None = None;
    has files: dict[str, File] = {};
    has projects: dict[str, Project] = {};
    has contributions: dict[str, dict[str, any]] = {};
    has symbol_index: dict[str, list[str]] = {};
}

walker DepReach {
    has claimed: dict[str, bool] = {};
    has target_cid: str = "";
    has hit: bool = False;

    can walk_file with File entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print {"dep_visit": here.cid};
        if here.cid == self.target_cid {
            self.hit = True;
        }
        kids: list[File] = [here ->:Depends:->][?:File];
        if len(kids) > 0 {
            for ch in kids {
                visit :0: [ch];
            }
        } else {
            disengage;
        }
    }
}

walker InvalidateSweep {
    has claimed: dict[str, bool] = {};
    has stale: list[str] = [];

    can sweep_file with File entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.stale.append(here.cid);
        print {"invalidate": here.cid};
        kids: list[File] = [here ->:Depends:->][?:File];
        if len(kids) > 0 {
            for ch in kids {
                visit :0: [ch];
            }
        } else {
            disengage;
        }
    }
}

def new_workspace -> SemanticWorkspace {
    return SemanticWorkspace();
}

def analyze_file(
    file_id: str,
    ast_hash: str,
    symbol_names: list[str],
    dependency_ids: list[str],
) -> dict[str, any] {
    symbols: list[str] = [];
    for s in symbol_names {
        symbols.append(s);
    }
    symbols = sorted(symbols);
    deps: list[str] = [];
    for d in dependency_ids {
        deps.append(d);
    }
    deps = sorted(deps);
    out: dict[str, any] = {};
    out["file_id"] = file_id;
    out["ast_hash"] = ast_hash;
    out["symbols"] = symbols;
    out["dependencies"] = deps;
    out["source_backed"] = True;
    return out;
}

def register_file(ws: SemanticWorkspace, cid: str, uri: str, ast_hash: str) -> File {
    nd = File(cid=cid, uri=uri, ast_hash=ast_hash);
    if ws.graph_root is None {
        ws.graph_root = nd;
        root ++> nd;
    }
    ws.files[cid] = nd;
    return nd;
}

def link_dependency(ws: SemanticWorkspace, src_cid: str, dst_cid: str) -> bool {
    if src_cid not in ws.files {
        return False;
    }
    if dst_cid not in ws.files {
        return False;
    }
    src = ws.files[src_cid];
    dst = ws.files[dst_cid];
    src +>:Depends:+> dst;
    return True;
}

def publish_contribution(ws: SemanticWorkspace, project_id: str, file_id: str, contribution: dict[str, any]) -> bool {
    if file_id not in ws.files {
        return False;
    }
    if project_id not in ws.projects {
        pr = Project(pid=project_id);
        ws.projects[project_id] = pr;
        if ws.graph_root is not None {
            ws.graph_root ++> pr;
        }
    }
    ws.contributions[file_id] = contribution;
    syms = contribution["symbols"] as list[str];
    for sym in syms {
        if sym not in ws.symbol_index {
            ws.symbol_index[sym] = [];
        }
        bucket: list[str] = ws.symbol_index[sym];
        present: bool = False;
        for existing in bucket {
            if existing == file_id {
                present = True;
            }
        }
        if not present {
            bucket.append(file_id);
        }
        ws.symbol_index[sym] = sorted(bucket);
    }
    return True;
}

def lookup_cross_file(ws: SemanticWorkspace, project_id: str, symbol: str) -> list[str] {
    if project_id not in ws.projects {
        return [];
    }
    if symbol not in ws.symbol_index {
        return [];
    }
    return ws.symbol_index[symbol];
}

def dependency_reachable(ws: SemanticWorkspace, start_cid: str, target_cid: str) -> bool {
    if start_cid not in ws.files {
        return False;
    }
    if target_cid not in ws.files {
        return False;
    }
    start = ws.files[start_cid];
    wk = start spawn DepReach(claimed={}, target_cid=target_cid);
    print {"reachable": wk.hit, "from": start_cid, "to": target_cid};
    return wk.hit;
}

def cascade_invalidate(ws: SemanticWorkspace, origin_cid: str) -> list[str] {
    if origin_cid not in ws.files {
        return [];
    }
    origin = ws.files[origin_cid];
    wk = origin spawn InvalidateSweep(claimed={});
    print {"cascade_origin": origin_cid, "count": len(wk.stale)};
    out: list[str] = [];
    for cid in wk.stale {
        out.append(cid);
    }
    return sorted(out);
}

def disposition_consumers(records: list[dict[str, any]]) -> dict[str, any] {
    retire: list[str] = [];
    migrate: list[str] = [];
    replace: list[str] = [];
    for rec in records {
        kind = rec["kind"] as str;
        name = rec["name"] as str;
        if kind == "no_production_consumer" {
            retire.append(name);
        } elif kind == "workspace_adapter" {
            migrate.append(name);
        } else {
            replace.append(name);
        }
    }
    out: dict[str, any] = {};
    out["retire"] = sorted(retire);
    out["migrate"] = sorted(migrate);
    out["replace"] = sorted(replace);
    return out;
}

def retire_legacy_index(ws: SemanticWorkspace, project_id: str) -> bool {
    if project_id not in ws.projects {
        return False;
    }
    pr = ws.projects[project_id];
    pr.legacy_retired = True;
    return True;
}

def ensure_no_hidden_reparse(contribution: dict[str, any]) -> bool {
    if "reparsed" in contribution {
        return False;
    }
    return contribution["source_backed"] is True;
}

test "analyze_file_sorted_symbols_and_deps" {
    out = analyze_file("f1", "h1", ["z", "a"], ["b", "a"]);
    syms = out["symbols"] as list[str];
    deps = out["dependencies"] as list[str];
    assert syms == ["a", "z"];
    assert deps == ["a", "b"];
    assert out["source_backed"] is True;
}

test "lookup_cross_file_after_publish" {
    ws = new_workspace();
    register_file(ws, "a", "uri/a", "h1");
    c = analyze_file("a", "h1", ["Foo"], []);
    publish_contribution(ws, "proj1", "a", c);
    hits = lookup_cross_file(ws, "proj1", "Foo");
    assert hits == ["a"];
}

test "dependency_reachable_linear_chain" {
    ws = new_workspace();
    register_file(ws, "a", "uri/a", "h1");
    register_file(ws, "b", "uri/b", "h2");
    register_file(ws, "c", "uri/c", "h3");
    link_dependency(ws, "a", "b");
    link_dependency(ws, "b", "c");
    assert dependency_reachable(ws, "a", "c") is True;
    assert dependency_reachable(ws, "c", "a") is False;
}

test "cascade_invalidate_returns_sorted_closure" {
    ws = new_workspace();
    register_file(ws, "a", "uri/a", "h1");
    register_file(ws, "b", "uri/b", "h2");
    register_file(ws, "c", "uri/c", "h3");
    link_dependency(ws, "a", "b");
    link_dependency(ws, "b", "c");
    stale = cascade_invalidate(ws, "a");
    assert stale == ["a", "b", "c"];
}

test "disposition_consumers_buckets_sorted" {
    recs: list[dict[str, any]] = [];
    r1: dict[str, any] = {};
    r1["kind"] = "no_production_consumer";
    r1["name"] = "LegacyIndex";
    recs.append(r1);
    r2: dict[str, any] = {};
    r2["kind"] = "workspace_adapter";
    r2["name"] = "Adapter";
    recs.append(r2);
    r3: dict[str, any] = {};
    r3["kind"] = "other";
    r3["name"] = "Repl";
    recs.append(r3);
    out = disposition_consumers(recs);
    assert (out["retire"] as list[str]) == ["LegacyIndex"];
    assert (out["migrate"] as list[str]) == ["Adapter"];
    assert (out["replace"] as list[str]) == ["Repl"];
}

test "ensure_no_hidden_reparse_and_retire_legacy" {
    good: dict[str, any] = {};
    good["source_backed"] = True;
    assert ensure_no_hidden_reparse(good) is True;
    bad: dict[str, any] = {};
    bad["source_backed"] = True;
    bad["reparsed"] = True;
    assert ensure_no_hidden_reparse(bad) is False;
    ws = new_workspace();
    register_file(ws, "x", "uri/x", "hx");
    publish_contribution(ws, "p1", "x", good);
    assert retire_legacy_index(ws, "p1") is True;
    pr = ws.projects["p1"];
    assert pr.legacy_retired is True;
}
