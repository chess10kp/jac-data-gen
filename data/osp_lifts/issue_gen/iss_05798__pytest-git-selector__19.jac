"""05798/pytest-git-selector#19 — Import dep graph reverse closure to tests."""

obj ImportGraph {
    has nodes: dict[str, Module] = {};
    has tests: dict[str, bool] = {};
}
node Module { has path: str; }
edge Imports {}

walker ReverseWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    can step with Module entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        self.hits.append(here.path);
        visit [<-:Imports:<-][?:Module];
    }
}

def load_import_graph(
    files: list[str],
    deps: list[tuple[str, str]],
    tests: list[str],
) -> ImportGraph {
    g = ImportGraph();
    for f in files {
        if f not in g.nodes {
            nd = Module(path=f);
            root ++> nd;
            g.nodes[f] = nd;
        }
    }
    for t in tests { g.tests[t] = True; }
    for (user, provider) in deps {
        u = g.nodes.get(user, None);
        p = g.nodes.get(provider, None);
        if u is None or p is None { continue; }
        u +>:Imports:+> p;
    }
    return g;
}

def tests_for_changes(g: ImportGraph, changed: list[str]) -> list[str] {
    seen: dict[str, bool] = {};
    for seed in changed {
        nd = g.nodes.get(seed, None);
        if nd is None { continue; }
        w = nd spawn ReverseWalk(claimed={}, hits=[]);
        for p in w.hits { seen[p] = True; }
    }
    out: list[str] = [];
    for (h, _v) in seen.items() { if g.tests.get(h, False) { out.append(h); } }
    return sorted(out);
}
