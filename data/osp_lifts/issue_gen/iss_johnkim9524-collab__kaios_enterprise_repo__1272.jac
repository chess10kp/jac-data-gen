"""johnkim9524-collab/kaios_enterprise_repo#1272 — Governed dependency closure."""

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
