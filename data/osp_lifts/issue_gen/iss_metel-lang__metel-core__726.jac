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
