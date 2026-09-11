"""EffortlessMetrics/perl-lsp-swarm#5889 — Crate publish order and cascade unpublish."""

obj CrateGraph { has crates: dict[str, Crate] = {}; }
node Crate { has name: str; }
edge Requires {}

def load_crate_graph(
    crates: list[str],
    depends: list[tuple[str, str]],
) -> CrateGraph {
    g = CrateGraph();
    for name in crates {
        if name not in g.crates {
            nd = Crate(name=name);
            root ++> nd;
            g.crates[name] = nd;
        }
    }
    for (crate, dep) in depends {
        a = g.crates.get(crate, None);
        b = g.crates.get(dep, None);
        if a is not None and b is not None { b +>:Requires:+> a; }
    }
    return g;
}

def publish_order(g: CrateGraph) -> list[str] {
    indeg: dict[str, int] = {};
    for (name, nd) in g.crates.items() {
        indeg[name] = len([nd <-:Requires:<-][?:Crate]);
    }
    ready = sorted([n for (n, d) in indeg.items() if d == 0]);
    out: list[str] = [];
    while ready {
        cur = ready.pop(0);
        out.append(cur);
        nd = g.crates.get(cur, None);
        if nd is None { continue; }
        for dep in [nd ->:Requires:->][?:Crate] {
            indeg[dep.name] -= 1;
            if indeg[dep.name] == 0 { ready.append(dep.name); }
        }
        ready = sorted(ready);
    }
    if len(out) != len(g.crates) { raise ValueError("publish cycle"); }
    return out;
}

walker DepCollect {
    has claimed: dict[str, bool] = {};
    has found: list[Crate] = [];

    can step with Crate entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here);
        visit [->:Requires:->][?:Crate];
    }
}

def _disconnect_crate(g: CrateGraph, c: Crate) {
    for par in [c <-:Requires:<-][?:Crate] { par del ->:Requires:-> c; }
    for ch in [c ->:Requires:->][?:Crate] { c del ->:Requires:-> ch; }
    del c;
}

def remove_crate_cascade(g: CrateGraph, crate_name: str) -> list[str] {
    start = g.crates.get(crate_name, None);
    if start is None { return []; }
    w = start spawn DepCollect(claimed={}, found=[]);
    doomed = w.found;
    names = sorted([c.name for c in doomed]);
    for c in doomed {
        _disconnect_crate(g, c);
        g.crates.pop(c.name, None);
    }
    return names;
}
