"""Guard: johnkim9524-collab/kaios_enterprise_repo#1272."""

node RuntimeModule { has path: str; }
edge Requires {}

obj TrustGraph { has modules: dict[str, RuntimeModule] = {}; }

walker ClosureWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with RuntimeModule entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        self.reached.append(here.path);
        visit [->:Requires:->][?:RuntimeModule];
    }
}

def load_trust_graph(
    modules: list[str],
    edges: list[tuple[str, str]],
) -> TrustGraph {
    g = TrustGraph();
    for mod in modules {
        nd = RuntimeModule(path=mod);
        root ++> nd;
        g.modules[mod] = nd;
    }
    for (src, dst) in edges {
        a = g.modules.get(src, None);
        b = g.modules.get(dst, None);
        if a is not None and b is not None { a +>:Requires:+> b; }
    }
    return g;
}

def dependency_closure(g: TrustGraph, roots: list[str]) -> list[str] {
    acc: dict[str, bool] = {};
    for r in roots {
        nd = g.modules.get(r, None);
        if nd is None { continue; }
        w = nd spawn ClosureWalk(claimed=acc, reached=[]);
        for p in w.reached { acc[p] = True; }
        acc = w.claimed;
    }
    out: list[str] = [];
    for k in acc.keys() { out.append(k); }
    return sorted(out);
}

def rejects_escape(g: TrustGraph, roots: list[str], candidate: str) -> bool {
    closure = dependency_closure(g, roots);
    for p in closure {
        if p == candidate { return False; }
    }
    return True;
}

test "portal governed closure" {
    g = load_trust_graph(
        ["portal", "store", "proof", "schema", "escape"],
        [
            ("portal", "store"),
            ("portal", "proof"),
            ("proof", "schema"),
            ("escape", "portal"),
        ],
    );
    roots = ["portal", "store", "proof", "schema"];
    assert dependency_closure(g, roots) == ["portal", "proof", "schema", "store"];
    assert rejects_escape(g, roots, "escape") is True;
}

test "diamond closure once only" {
    g = load_trust_graph(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "leaf"),
            ("right", "leaf"),
        ],
    );
    assert dependency_closure(g, ["hub"]) == ["hub", "leaf", "left", "right"];
}

test "cycle safe revisit" {
    g = load_trust_graph(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert dependency_closure(g, ["a"]) == ["a", "b", "c"];
}
