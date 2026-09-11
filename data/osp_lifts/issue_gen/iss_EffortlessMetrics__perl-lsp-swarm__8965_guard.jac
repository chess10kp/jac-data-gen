"""EffortlessMetrics/perl-lsp-swarm#8965 — cut generated-member consumers over to canonical adapter facts."""

obj MooModel {
    has classes: set[str] = set();
    has parent: dict[str, str] = {};
    has roles: dict[str, list[str]] = {};
    has canonical: dict[str, set[str]] = {};
    has producers: dict[tuple[str, str], list[str]] = {};
    has nodes: dict[str, MooClass] = {};
}

node MooClass {
    has cid: str;
}

edge Extends {}
edge WithRole {}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with MooClass entry {
        parents = [here ->:Extends:->][?:MooClass];
        if len(parents) == 0 { disengage; }
        p = parents[0];
        if p.cid in self.claimed { skip; }
        self.claimed[p.cid] = True;
        self.chain.append(p.cid);
        visit [p];
    }
}

walker FactHolderPathWalk {
    has trail: list[str] = [];
    has paths: list[list[str]] = [];
    has fact_id: str = "";
    has max_depth: int = 8;
    has canonical: dict[str, set[str]] = {};

    can step with MooClass entry {
        if here.cid in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.cid);
        facts = self.canonical.get(here.cid, set());
        if self.fact_id in facts {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        nbrs: list[MooClass] = [];
        for p in [here ->:Extends:->][?:MooClass] { nbrs.append(p); }
        for r in [here ->:WithRole:->][?:MooClass] { nbrs.append(r); }
        nms: list[str] = [];
        for n in nbrs { nms.append(n.cid); }
        for nm in sorted(nms) {
            for n in nbrs {
                if n.cid == nm and n.cid not in nt {
                    n spawn FactHolderPathWalk(
                        trail=nt,
                        paths=self.paths,
                        fact_id=self.fact_id,
                        max_depth=self.max_depth,
                        canonical=self.canonical,
                    );
                }
            }
        }
    }
}

def _sorted_lineage_neighbors(nd: MooClass) -> list[str] {
    nbrs: list[str] = [];
    for p in [nd ->:Extends:->][?:MooClass] { nbrs.append(p.cid); }
    for r in [nd ->:WithRole:->][?:MooClass] { nbrs.append(r.cid); }
    return sorted(nbrs);
}

def _lineage_bfs_wave(
    m: MooModel,
    frontier: list[str],
    depth: int,
    max_depth: int,
    claimed: dict[str, bool],
    order: list[str],
    origin: str,
) -> None {
    if len(frontier) == 0 { return; }
    for cid in frontier {
        if cid != origin { order.append(cid); }
    }
    if depth >= max_depth { return; }
    nxt: list[str] = [];
    for cid in frontier {
        nd = m.nodes.get(cid, None);
        if nd is None { continue; }
        for nb in _sorted_lineage_neighbors(nd) {
            if nb not in claimed {
                claimed[nb] = True;
                nxt.append(nb);
            }
        }
    }
    _lineage_bfs_wave(m, nxt, depth + 1, max_depth, claimed, order, origin);
}

def load_moo_model(
    classes: list[str],
    extends: list[tuple[str, str]],
    with_roles: list[tuple[str, str]],
    canonical_facts: list[tuple[str, str]],
    duplicate_producers: list[tuple[str, str, str]],
) -> MooModel {
    m = MooModel();
    for cls in classes {
        m.classes.add(cls);
        if cls not in m.roles { m.roles[cls] = []; }
        if cls not in m.canonical { m.canonical[cls] = set(); }
        if cls not in m.nodes {
            nd = MooClass(cid=cls);
            root ++> nd;
            m.nodes[cls] = nd;
        }
    }
    for (child, par) in extends {
        if child in m.classes and par in m.classes {
            m.parent[child] = par;
            c = m.nodes.get(child, None);
            p = m.nodes.get(par, None);
            if c is not None and p is not None { c +>:Extends:+> p; }
        }
    }
    for (cls, role) in with_roles {
        if cls in m.classes and role in m.classes {
            m.roles[cls].append(role);
            c = m.nodes.get(cls, None);
            r = m.nodes.get(role, None);
            if c is not None and r is not None { c +>:WithRole:+> r; }
        }
    }
    for (cls, fact) in canonical_facts {
        if cls in m.classes { m.canonical[cls].add(fact); }
    }
    for (consumer, fact, producer) in duplicate_producers {
        key = (consumer, fact);
        if key not in m.producers { m.producers[key] = []; }
        plist = m.producers[key];
        dup = False;
        for p in plist {
            if p == producer { dup = True; }
        }
        if not dup { plist.append(producer); }
    }
    return m;
}

def upstream_lineage(m: MooModel, class_id: str) -> list[str] {
    if class_id not in m.classes { return []; }
    nd = m.nodes.get(class_id, None);
    if nd is None { return []; }
    w = nd spawn UpstreamWalk(claimed={class_id: True}, chain=[]);
    return w.chain;
}

def lineage_bfs_reach(m: MooModel, start: str, max_depth: int = 12) -> list[str] {
    if start not in m.classes { return []; }
    claimed: dict[str, bool] = {start: True};
    order: list[str] = [];
    _lineage_bfs_wave(m, [start], 0, max_depth, claimed, order, start);
    return order;
}

def fact_holder_paths(
    m: MooModel,
    consumer: str,
    fact_id: str,
    max_depth: int = 8,
) -> list[list[str]] {
    if consumer not in m.classes { return []; }
    nd = m.nodes.get(consumer, None);
    if nd is None { return []; }
    w = nd spawn FactHolderPathWalk(
        trail=[],
        paths=[],
        fact_id=fact_id,
        max_depth=max_depth,
        canonical=m.canonical,
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def cutover_route(
    *,
    has_canonical: bool,
    shadow_ok: bool,
    freshness_ok: bool,
    semantic_ok: bool,
    provider_ready: bool,
) -> str {
    if not has_canonical { return "refusal"; }
    if shadow_ok and freshness_ok and semantic_ok and provider_ready {
        return "canonical";
    }
    return "fallback";
}

def duplicate_path_inventory(m: MooModel, consumer: str, fact_id: str) -> dict[str, str] {
    key = (consumer, fact_id);
    plist = m.producers.get(key, []);
    producers: list[str] = [];
    for p in plist { producers.append(p); }
    producers = sorted(producers);
    if len(producers) == 0 { return {}; }
    holders = fact_holder_paths(m, consumer, fact_id);
    if len(holders) == 0 {
        inv: dict[str, str] = {};
        for p in producers {
            if p.startswith("test_") {
                inv[p] = "retained_standalone_test_only";
            } else {
                inv[p] = "retained_bounded_fallback_for_named_unsupported_form";
            }
        }
        return inv;
    }
    owner = holders[0][-1];
    canon_id = f"canonical:{owner}";
    inv2: dict[str, str] = {};
    for p in producers {
        if p == canon_id {
            inv2[p] = "transferred_to_canonical_owner";
        } elif p.startswith("test_") {
            inv2[p] = "retained_standalone_test_only";
        } else {
            inv2[p] = "removed_after_cutover";
        }
    }
    return inv2;
}

test "lineage bfs diamond hub claimed once" {
    m = load_moo_model(
        ["child", "left", "right", "hub"],
        [("left", "hub"), ("right", "hub")],
        [("child", "left"), ("child", "right")],
        [],
        [],
    );
    assert lineage_bfs_reach(m, "child") == ["left", "right", "hub"];
    assert lineage_bfs_reach(m, "hub") == [];
}

test "upstream lineage cycle stops without disengage" {
    m = load_moo_model(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
        [],
        [],
        [],
    );
    assert upstream_lineage(m, "a") == ["b", "c"];
    assert upstream_lineage(m, "missing") == [];
}

test "unknown ids and invalid extends tolerance" {
    m = load_moo_model(
        ["only"],
        [("only", "ghost"), ("ghost", "only")],
        [("only", "phantom")],
        [("only", "fact_x")],
        [("only", "fact_x", "orphan_prod")],
    );
    assert lineage_bfs_reach(m, "ghost") == [];
    assert fact_holder_paths(m, "ghost", "fact_x") == [];
    assert duplicate_path_inventory(m, "ghost", "fact_x") == {};
    assert duplicate_path_inventory(m, "only", "no_such_fact") == {};
    assert duplicate_path_inventory(m, "only", "fact_x") == {
        "orphan_prod": "removed_after_cutover",
    };
}

test "fact holder paths diamond depth and sort" {
    m = load_moo_model(
        ["consumer", "left", "right", "hub"],
        [("left", "hub"), ("right", "hub")],
        [("consumer", "right"), ("consumer", "left")],
        [("hub", "target_fact")],
        [],
    );
    assert fact_holder_paths(m, "consumer", "target_fact") == [
        ["consumer", "left", "hub"],
        ["consumer", "right", "hub"],
    ];
    assert fact_holder_paths(m, "consumer", "target_fact", max_depth=2) == [];
    assert fact_holder_paths(m, "hub", "target_fact") == [["hub"]];
}

test "duplicate path inventory cutover matrix" {
    m = load_moo_model(
        ["consumer", "role_a", "owner"],
        [("role_a", "owner")],
        [("consumer", "role_a")],
        [("owner", "fact_z")],
        [
            ("consumer", "fact_z", "canonical:owner"),
            ("consumer", "fact_z", "test_shadow"),
            ("consumer", "fact_z", "legacy_dup"),
            ("consumer", "fact_z", "legacy_dup"),
        ],
    );
    assert duplicate_path_inventory(m, "consumer", "fact_z") == {
        "canonical:owner": "transferred_to_canonical_owner",
        "legacy_dup": "removed_after_cutover",
        "test_shadow": "retained_standalone_test_only",
    };
}

test "cutover route refusal and partial readiness" {
    assert cutover_route(
        has_canonical=False,
        shadow_ok=True,
        freshness_ok=True,
        semantic_ok=True,
        provider_ready=True,
    ) == "refusal";
    assert cutover_route(
        has_canonical=True,
        shadow_ok=True,
        freshness_ok=True,
        semantic_ok=False,
        provider_ready=True,
    ) == "fallback";
    assert cutover_route(
        has_canonical=True,
        shadow_ok=True,
        freshness_ok=True,
        semantic_ok=True,
        provider_ready=True,
    ) == "canonical";
}
