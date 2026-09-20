"""OSINT domain-server orchestration gap mapper.

lost-rob0t/starintel-auto-research#165
"""

node Capability {
    has cid: str;
    has semantic: str;
    has classification: str = "unknown";
}

edge Depends {}

walker LineageWalker {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 3;
    has depth: int = 0;
    has found: list[str] = [];

    can step with Capability entry {
        if here.cid in self.claimed {
            skip;
        }
        if self.depth >= self.max_depth {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print("lineage", here.cid);
        kids: list[Capability] = [here ->:Depends:->][?:Capability];
        cids: list[str] = [];
        for kid in kids {
            cids.append(kid.cid);
        }
        cids = sorted(cids);
        sorted_kids: list[Capability] = [];
        for cid in cids {
            for kid in kids {
                if kid.cid == cid {
                    sorted_kids.append(kid);
                    break;
                }
            }
        }
        if sorted_kids {
            self.depth += 1;
            visit :0: sorted_kids;
        }
    }
}

walker PivotWalker {
    has claimed: dict[str, bool] = {};
    has budget: int = 0;
    has spent: int = 0;
    has found: list[str] = [];

    can pivot with Capability entry {
        if here.cid in self.claimed {
            skip;
        }
        if self.spent >= self.budget {
            skip;
        }
        self.claimed[here.cid] = True;
        self.spent += 1;
        self.found.append(here.cid);
        print("pivot", here.cid);
        kids: list[Capability] = [here ->:Depends:->][?:Capability];
        cids: list[str] = [];
        for kid in kids {
            cids.append(kid.cid);
        }
        cids = sorted(cids);
        sorted_kids: list[Capability] = [];
        for cid in cids {
            for kid in kids {
                if kid.cid == cid {
                    sorted_kids.append(kid);
                    break;
                }
            }
        }
        if sorted_kids {
            visit sorted_kids;
        }
    }
}

def _seed_catalog(catalog: dict[str, str]) -> None {
    catalog["domain-server"] = "already_supported";
    catalog["wire-dispatcher"] = "already_supported";
    catalog["runtime-journal"] = "already_supported";
    catalog["bounded-recursive-pivots"] = "expressible_now";
    catalog["bounded-parallel-fanout"] = "extension_needed";
    catalog["circuit-breaker-demotion"] = "extension_needed";
    catalog["tor-transport-policy"] = "lisp_adapter_needed";
    catalog["spiderfoot-orchestration"] = "external_process_required";
}

def _build_research_graph(store: dict[str, Capability]) -> Capability {
    ds = Capability(
        cid="domain-server",
        semantic="domain-server",
        classification="already_supported",
    );
    wd = Capability(
        cid="wire-dispatcher",
        semantic="wire-dispatcher",
        classification="already_supported",
    );
    jr = Capability(
        cid="runtime-journal",
        semantic="runtime-journal",
        classification="already_supported",
    );
    brp = Capability(
        cid="bounded-recursive-pivots",
        semantic="bounded-recursive-pivots",
        classification="expressible_now",
    );
    bpf = Capability(
        cid="bounded-parallel-fanout",
        semantic="bounded-parallel-fanout",
        classification="extension_needed",
    );
    root ++> ds;
    ds +>:Depends:+> wd;
    ds +>:Depends:+> jr;
    ds +>:Depends:+> bpf;
    bpf +>:Depends:+> brp;
    store["domain-server"] = ds;
    store["wire-dispatcher"] = wd;
    store["runtime-journal"] = jr;
    store["bounded-recursive-pivots"] = brp;
    store["bounded-parallel-fanout"] = bpf;
    return ds;
}

def classify_semantic(semantic_id: str) -> str {
    catalog: dict[str, str] = {};
    _seed_catalog(catalog);
    if semantic_id in catalog {
        return catalog[semantic_id];
    }
    return "extension_needed";
}

def collect_lineage(root_id: str, max_depth: int) -> list[str] {
    store: dict[str, Capability] = {};
    _ = _build_research_graph(store);
    if root_id not in store {
        return [];
    }
    start = store[root_id] as Capability;
    w = start spawn LineageWalker(
        claimed={},
        max_depth=max_depth,
        depth=0,
        found=[],
    );
    return sorted(w.found);
}

def bounded_pivot(root_id: str, budget: int) -> list[str] {
    store: dict[str, Capability] = {};
    _ = _build_research_graph(store);
    if root_id not in store {
        return [];
    }
    start = store[root_id] as Capability;
    w = start spawn PivotWalker(
        claimed={},
        budget=budget,
        spent=0,
        found=[],
    );
    return sorted(w.found);
}

with entry {
    store: dict[str, Capability] = {};
    _ = _build_research_graph(store);
    root spawn LineageWalker(claimed={}, max_depth=2, depth=0, found=[]);
}

test "classify_semantic_known" {
    assert classify_semantic("domain-server") == "already_supported";
    assert classify_semantic("tor-transport-policy") == "lisp_adapter_needed";
    assert classify_semantic("unknown-widget") == "extension_needed";
}

test "collect_lineage_full_graph" {
    got = collect_lineage("domain-server", 5);
    assert got == [
        "bounded-parallel-fanout",
        "bounded-recursive-pivots",
        "domain-server",
        "runtime-journal",
        "wire-dispatcher",
    ];
}

test "lineage_diamond_revisit_counts_sink_once" {
    apex = Capability(cid="apex", semantic="apex", classification="test");
    left = Capability(cid="left", semantic="left", classification="test");
    right = Capability(cid="right", semantic="right", classification="test");
    sink = Capability(cid="sink", semantic="sink", classification="test");
    root ++> apex;
    apex +>:Depends:+> left;
    apex +>:Depends:+> right;
    left +>:Depends:+> sink;
    right +>:Depends:+> sink;
    w = apex spawn LineageWalker(claimed={}, max_depth=5, depth=0, found=[]);
    assert sorted(w.found) == ["apex", "left", "right", "sink"];
}

test "bounded_pivot_respects_budget_cap" {
    got = bounded_pivot("domain-server", 2);
    assert got == ["bounded-parallel-fanout", "domain-server"];
}

test "unknown_root_returns_empty" {
    assert collect_lineage("missing-node", 3) == [];
    assert bounded_pivot("missing-node", 2) == [];
}

test "lineage_depth_cap_stops_expansion" {
    got = collect_lineage("domain-server", 1);
    assert got == ["domain-server"];
}
