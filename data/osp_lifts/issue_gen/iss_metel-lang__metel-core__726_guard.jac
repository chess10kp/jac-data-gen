# RFC-0132 design settlement — metel-lang/metel-core#726
# Comptime dependency graph: `comptime let` / `comptime fun` values, their
# static dep edges, compiler-enforced recursion depth budget, and closure
# resolution over the comptime graph (claim-map cycle policy).

node CNode {
    has cid: str;
    has name: str;
    has kind: str = "comptime_let";
}

edge DependsOn {}

# Build the comptime graph. specs: list of (cid, name, kind, [dep cids]).
def build_comptime_graph(specs: list[tuple]) -> dict[str, CNode] {
    nodes: dict[str, CNode] = {};
    dep_pairs: list[tuple] = [];
    for sp in specs {
        nd = CNode(cid=sp[0], name=sp[1], kind=sp[2]);
        nodes[sp[0]] = nd;
        for d in sp[3] {
            dep_pairs.append((sp[0], d));
        }
    }
    for pr in dep_pairs {
        src = nodes[pr[0]];
        dst = nodes[pr[1]];
        src +>:DependsOn:+> dst;
    }
    return nodes;
}

# Unknown-id tolerance: missing comptime symbol resolves to None.
def lookup(nodes: dict[str, CNode], cid: str) -> CNode | None {
    if cid in nodes {
        return nodes[cid];
    }
    return None;
}

# Depth budget = compiler-enforced recursion limit (Zig-style answer to OQ1).
walker ClosureWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has limit: int = 64;
    can step with CNode entry {
        if here.cid in self.claimed {
            skip;
        }
        if len(self.claimed) >= self.limit {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid + ":" + here.kind);
        print("resolved " + here.cid + " (" + here.kind + ")");
        visit [here ->:DependsOn:->];
    }
}

# Public API: resolve the full comptime closure rooted at a symbol.
# Returns None for unknown ids (matches source tolerance).
def resolve_comptime(nodes: dict[str, CNode], root_cid: str) -> ClosureWalk | None {
    nd = lookup(nodes, root_cid);
    if nd is None {
        return None;
    }
    w = nd spawn ClosureWalk(claimed={}, order=[], limit=64);
    return w;
}

with entry {
    spec: list[tuple] = [
        ("banner", "BANNER", "comptime_let", ["version"]),
        ("version", "VERSION", "comptime_let", ["verfun"]),
        ("verfun", "ver_str", "comptime_fun", []),
    ];
    g = build_comptime_graph(specs);
    w = resolve_comptime(g, "banner");
    print(sorted(w.claimed));
}

test "diamond_revisit_claim_map" {
    specs: list[tuple] = [
        ("a", "A", "comptime_let", ["b", "c"]),
        ("b", "B", "comptime_let", ["d"]),
        ("c", "C", "comptime_let", ["d"]),
        ("d", "D", "comptime_let", []),
    ];
    g = build_comptime_graph(specs);
    w = resolve_comptime(g, "a");
    assert w is not None;
    assert sorted(w.order) == ["a:comptime_let", "b:comptime_let", "c:comptime_let", "d:comptime_let"];
    assert w.claimed["d"] == True;
    assert len(w.claimed) == 4;
}

test "adversarial_order_diamond" {
    # d is first reached via c's subtree before b's first visit fires;
    # the claim-map must still dedup d exactly once.
    specs: list[tuple] = [
        ("a", "A", "comptime_let", ["c", "b"]),
        ("c", "C", "comptime_let", ["d"]),
        ("b", "B", "comptime_let", ["d"]),
        ("d", "D", "comptime_let", []),
    ];
    g = build_comptime_graph(specs);
    w = resolve_comptime(g, "a");
    assert w is not None;
    assert sorted(w.order) == ["a:comptime_let", "b:comptime_let", "c:comptime_let", "d:comptime_let"];
    assert w.claimed["d"] == True;
    assert w.claimed["b"] == True;
}

test "unknown_id_tolerance" {
    specs: list[tuple] = [("x", "X", "comptime_let", [])];
    g = build_comptime_graph(specs);
    assert resolve_comptime(g, "nope") is None;
    assert lookup(g, "missing") is None;
    assert lookup(g, "x") is not None;
}

test "comptime_string_interpolation_chain" {
    # OQ2 growable-shape: BANNER -> VERSION -> comptime fun chain.
    specs: list[tuple] = [
        ("banner", "BANNER", "comptime_let", ["version"]),
        ("version", "VERSION", "comptime_let", ["tostr"]),
        ("tostr", "to_string", "comptime_fun", []),
    ];
    g = build_comptime_graph(specs);
    w = resolve_comptime(g, "banner");
    assert w is not None;
    assert sorted(w.order) == ["banner:comptime_let", "tostr:comptime_fun", "version:comptime_let"];
    assert w.claimed["tostr"] == True;
}

test "recursion_depth_budget" {
    # Cycle b -> c -> b with a tiny budget: claim-map + skip terminate it.
    specs: list[tuple] = [
        ("b", "B", "comptime_fun", ["c"]),
        ("c", "C", "comptime_fun", ["b"]),
    ];
    g = build_comptime_graph(specs);
    w = resolve_comptime(g, "b");
    assert w is not None;
    assert sorted(w.order) == ["b:comptime_fun", "c:comptime_fun"];
    assert len(w.claimed) == 2;
}

test "isolated_single_node" {
    specs: list[tuple] = [("solo", "SOLO", "comptime_let", [])];
    g = build_comptime_graph(specs);
    w = resolve_comptime(g, "solo");
    assert w is not None;
    assert w.order == ["solo:comptime_let"];
    assert len(w.claimed) == 1;
}
