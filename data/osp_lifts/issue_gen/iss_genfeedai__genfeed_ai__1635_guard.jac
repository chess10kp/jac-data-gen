"""Guard: genfeedai/genfeed.ai#1635."""

obj ModuleGraph { has modules: dict[str, ModNode] = {}; }
node ModNode { has name: str; }
edge Imports {}

walker ImportHop {
    has claimed: dict[str, bool];
    has next: list[ModNode] = [];

    can step with ModNode entry {
        for nxt in [here ->:Imports:->][?:ModNode] {
            if nxt.name in self.claimed { continue; }
            self.claimed[nxt.name] = True;
            self.next.append(nxt);
        }
    }
}

def load_modules(
    modules: list[str],
    edges: list[tuple[str, str]],
) -> ModuleGraph {
    g = ModuleGraph(modules={});
    for m in modules {
        n = ModNode(name=m);
        root ++> n;
        g.modules[m] = n;
    }
    for (src, dst) in edges {
        a = g.modules.get(src, None);
        b = g.modules.get(dst, None);
        if a is not None and b is not None { a +>:Imports:+> b; }
    }
    return g;
}

def reachable_from_entries(g: ModuleGraph, entries: list[str]) -> list[str] {
    claimed: dict[str, bool] = {};
    reached: list[str] = [];
    frontier: list[ModNode] = [];
    for e in entries {
        anchor = g.modules.get(e, None);
        if anchor is None { continue; }
        if e not in claimed {
            claimed[e] = True;
            reached.append(e);
            frontier.append(anchor);
        }
    }
    while len(frontier) > 0 {
        nxt: list[ModNode] = [];
        for f in frontier {
            w = f spawn ImportHop(claimed=claimed, next=nxt);
            nxt = w.next;
        }
        for n in nxt { reached.append(n.name); }
        frontier = nxt;
    }
    return sorted(reached);
}

def orphan_modules(g: ModuleGraph, entries: list[str]) -> list[str] {
    reach: dict[str, bool] = {};
    for m in reachable_from_entries(g, entries) { reach[m] = True; }
    out: list[str] = [];
    for k in g.modules.keys() {
        if k not in reach { out.append(k); }
    }
    return sorted(out);
}

test "entry reachability and orphans" {
    g = load_modules(
        ["main", "api", "db", "util", "dead"],
        [("main", "api"), ("api", "db"), ("api", "util"), ("dead", "util")],
    );
    assert reachable_from_entries(g, ["main"]) == ["api", "db", "main", "util"];
    assert orphan_modules(g, ["main"]) == ["dead"];
}

test "import cycle still reaches leaf" {
    g = load_modules(
        ["a", "b", "c", "leaf"],
        [("a", "b"), ("b", "c"), ("c", "a"), ("c", "leaf")],
    );
    assert reachable_from_entries(g, ["a"]) == ["a", "b", "c", "leaf"];
}

test "diamond adversarial order" {
    g = load_modules(
        ["root", "left", "right", "sink"],
        [("root", "left"), ("root", "right"), ("left", "sink"), ("right", "sink")],
    );
    assert reachable_from_entries(g, ["root"]) == ["left", "right", "root", "sink"];
}

test "unknown entry tolerant" {
    g = load_modules(["solo"], []);
    assert reachable_from_entries(g, ["missing"]) == [];
    assert orphan_modules(g, ["main", "dead"]) == ["solo"];
}
