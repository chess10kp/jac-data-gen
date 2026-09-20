"""lyh970817/gwas#27 — workflow DAG reachability audit and orphan removal."""

node Component {
    has cid: str;
    has kind: str;
    has retain_standalone: bool = False;
    has test_only: bool = False;
    has purged: bool = False;
}

edge Depends {}
edge References {}

walker ReachAudit {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Component entry {
        if here.purged {
            skip;
        }
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print("reach ", here.cid);
        nbrs: list[Component] = [];
        for dep in [here ->:Depends:->][?:Component] {
            if not dep.purged {
                nbrs.append(dep);
            }
        }
        for ref in [here ->:References:->][?:Component] {
            if not ref.purged {
                nbrs.append(ref);
            }
        }
        if len(nbrs) > 0 {
            visit :0: nbrs;
        } else {
            disengage;
        }
    }
}

def index_components(graph_root: Component) -> dict[str, Component] {
    store: dict[str, Component] = {};
    stack: list[Component] = [graph_root];
    seen: dict[str, bool] = {};
    while len(stack) > 0 {
        nd = stack.pop();
        if nd.cid in seen {
            continue;
        }
        seen[nd.cid] = True;
        store[nd.cid] = nd;
        for ch in [nd ->:Depends:->][?:Component] {
            stack.append(ch);
        }
        for ch in [nd ->:References:->][?:Component] {
            stack.append(ch);
        }
    }
    return store;
}

def collect_reachable(graph_root: Component, seed_ids: list[str]) -> list[str] {
    idx = index_components(graph_root);
    merged: dict[str, bool] = {};
    for sid in seed_ids {
        if sid not in idx {
            continue;
        }
        seed = idx[sid];
        if seed.purged {
            continue;
        }
        w = seed spawn ReachAudit(claimed={}, found=[]);
        for cid in w.found {
            merged[cid] = True;
        }
    }
    out: list[str] = [];
    for cid in merged {
        out.append(cid);
    }
    return sorted(out);
}

def classify_all(
    graph_root: Component,
    seed_ids: list[str],
    superseded: list[str],
) -> dict[str, str] {
    idx = index_components(graph_root);
    reach_set: dict[str, bool] = {};
    reach_list = collect_reachable(graph_root, seed_ids);
    for r in reach_list {
        reach_set[r] = True;
    }
    super_set: dict[str, bool] = {};
    for s in superseded {
        super_set[s] = True;
    }
    labels: dict[str, str] = {};
    for cid in idx {
        nd = idx[cid];
        if nd.purged {
            continue;
        }
        if cid in super_set {
            labels[cid] = "superseded_duplicate";
        elif nd.test_only {
            labels[cid] = "test_only";
        elif nd.retain_standalone {
            labels[cid] = "standalone_reusable";
        elif cid in reach_set {
            labels[cid] = "active_production";
        } else {
            labels[cid] = "orphaned";
        }
    }
    return labels;
}

def removable_ids(
    graph_root: Component,
    seed_ids: list[str],
    superseded: list[str],
) -> list[str] {
    classes = classify_all(graph_root, seed_ids, superseded);
    out: list[str] = [];
    for cid in classes {
        tag = classes[cid];
        if tag == "orphaned" or tag == "superseded_duplicate" {
            out.append(cid);
        }
    }
    return sorted(out);
}

def apply_removals(graph_root: Component, target_ids: list[str]) -> list[str] {
    idx = index_components(graph_root);
    applied: list[str] = [];
    for tid in sorted(target_ids) {
        if tid not in idx {
            continue;
        }
        nd = idx[tid];
        if nd.purged {
            continue;
        }
        nd.purged = True;
        applied.append(tid);
    }
    return applied;
}

def build_audit_graph -> Component {
    graph_root = Component(cid="GRAPH_ROOT", kind="root");
    route_regenie = Component(cid="ROUTE_REGENIE_ASSOCIATIONS", kind="route");
    route_ldak = Component(cid="ROUTE_LDAK_KVIK_ASSOCIATIONS", kind="route");
    plink_fit = Component(cid="PLINK_FIT_REGENIE", kind="module");
    mod_a = Component(cid="MOD_A", kind="module");
    mod_b = Component(cid="MOD_B", kind="module");
    shared = Component(cid="SHARED_THIN", kind="module");
    dup_regenie = Component(cid="plink_gwas_regenie", kind="subworkflow");
    dup_ldak = Component(cid="plink_association_ldak_kvik", kind="subworkflow");
    orphan_grms = Component(cid="ldak/addgrms", kind="module");
    standalone = Component(cid="SUMHER_BUNDLE", kind="module", retain_standalone=True);
    test_mod = Component(cid="SELF_TEST_MOD", kind="module", test_only=True);
    graph_root ++> route_regenie;
    graph_root ++> route_ldak;
    graph_root ++> dup_regenie;
    graph_root ++> dup_ldak;
    graph_root ++> orphan_grms;
    graph_root ++> standalone;
    graph_root ++> test_mod;
    route_regenie +>:Depends:+> plink_fit;
    route_regenie +>:Depends:+> mod_a;
    route_ldak +>:Depends:+> mod_b;
    mod_a +>:Depends:+> shared;
    mod_b +>:Depends:+> shared;
    shared +>:References:+> route_regenie;
    plink_fit +>:Depends:+> shared;
    return graph_root;
}

test "collect_reachable_from_routes" {
    root_node = build_audit_graph();
    seeds = ["ROUTE_REGENIE_ASSOCIATIONS", "ROUTE_LDAK_KVIK_ASSOCIATIONS"];
    got = collect_reachable(root_node, seeds);
    want = [
        "MOD_A",
        "MOD_B",
        "PLINK_FIT_REGENIE",
        "ROUTE_LDAK_KVIK_ASSOCIATIONS",
        "ROUTE_REGENIE_ASSOCIATIONS",
        "SHARED_THIN",
    ];
    assert got == want;;
}

test "classify_all_tags" {
    root_node = build_audit_graph();
    seeds = ["ROUTE_REGENIE_ASSOCIATIONS", "ROUTE_LDAK_KVIK_ASSOCIATIONS"];
    superseded = ["plink_gwas_regenie", "plink_association_ldak_kvik"];
    got = classify_all(root_node, seeds, superseded);
    assert got["MOD_A"] == "active_production";;
    assert got["SUMHER_BUNDLE"] == "standalone_reusable";;
    assert got["SELF_TEST_MOD"] == "test_only";;
    assert got["plink_gwas_regenie"] == "superseded_duplicate";;
    assert got["ldak/addgrms"] == "orphaned";;
    assert got["GRAPH_ROOT"] == "orphaned";;
}

test "removable_ids_sorted" {
    root_node = build_audit_graph();
    seeds = ["ROUTE_REGENIE_ASSOCIATIONS", "ROUTE_LDAK_KVIK_ASSOCIATIONS"];
    superseded = ["plink_gwas_regenie", "plink_association_ldak_kvik"];
    got = removable_ids(root_node, seeds, superseded);
    want = [
        "GRAPH_ROOT",
        "ldak/addgrms",
        "plink_association_ldak_kvik",
        "plink_gwas_regenie",
    ];
    assert got == want;;
}

test "apply_removals_skips_unknown_and_purged" {
    root_node = build_audit_graph();
    got = apply_removals(root_node, ["ldak/addgrms", "MISSING", "ldak/addgrms"]);
    assert got == ["ldak/addgrms"];;
    idx = index_components(root_node);
    assert idx["ldak/addgrms"].purged == True;;
}

test "purged_nodes_drop_from_reachability" {
    root_node = build_audit_graph();
    apply_removals(root_node, ["SHARED_THIN"]);
    seeds = ["ROUTE_REGENIE_ASSOCIATIONS"];
    got = collect_reachable(root_node, seeds);
    assert "SHARED_THIN" not in got;;
    assert "ROUTE_REGENIE_ASSOCIATIONS" in got;;
}
