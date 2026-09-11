"""99x/xianix-team#3 — PR merge impact via dependency graph reachability."""

node Module {
    has mid: str;
}

edge DependsOn {}

obj ModuleGraph {
    has modules: dict[str, Module] = {};
}

walker ReverseReach {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has max_depth: int = 3;
    has depth: int = 0;

    can step with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.hits.append(here.mid);
        if self.depth >= self.max_depth { disengage; }
        self.depth += 1;
        visit [<-:DependsOn:<-][?:Module];
    }
}

walker ForwardClosure {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.hits.append(here.mid);
        visit [->:DependsOn:->][?:Module];
    }
}

def load_module_graph(
    modules: list[str],
    depends: list[tuple[str, str]],
) -> ModuleGraph {
    g = ModuleGraph();
    for m in modules {
        if m not in g.modules {
            nd = Module(mid=m);
            root ++> nd;
            g.modules[m] = nd;
        }
    }
    for (user, provider) in depends {
        u = g.modules.get(user, None);
        p = g.modules.get(provider, None);
        if u is not None and p is not None { u +>:DependsOn:+> p; }
    }
    return g;
}

def impacted_modules(g: ModuleGraph, changed: list[str], max_depth: int = 3) -> list[str] {
    changed_set: dict[str, bool] = {};
    for c in changed { changed_set[c] = True; }
    seen: dict[str, bool] = {};
    pending: list[tuple[str, int]] = [];
    for seed in changed {
        if seed in g.modules { pending.append((seed, 0)); }
    }
    while len(pending) > 0 {
        (cur, depth) = pending.pop(0);
        if cur in seen { continue; }
        seen[cur] = True;
        if depth >= max_depth { continue; }
        nd = g.modules.get(cur, None);
        if nd is None { continue; }
        for nb in [nd <-:DependsOn:<-][?:Module] {
            if nb.mid not in seen { pending.append((nb.mid, depth + 1)); }
        }
    }
    out: list[str] = [];
    for mid in seen {
        if mid not in changed_set { out.append(mid); }
    }
    return sorted(out);
}

def direct_dependents(g: ModuleGraph, module_id: str) -> list[str] {
    nd = g.modules.get(module_id, None);
    if nd is None { return []; }
    return sorted([m.mid for m in [nd <-:DependsOn:<-][?:Module]]);
}

def dependency_closure(g: ModuleGraph, module_id: str) -> list[str] {
    nd = g.modules.get(module_id, None);
    if nd is None { return []; }
    w = nd spawn ForwardClosure(claimed={}, hits=[]);
    out: list[str] = [];
    for h in w.hits {
        if h != module_id { out.append(h); }
    }
    return sorted(out);
}
test "impact reverse reach" {
    g = load_module_graph(
        ["api", "core", "db", "ui", "auth"],
        [("ui", "api"), ("api", "core"), ("api", "auth"), ("core", "db")],
    );
    assert impacted_modules(g, ["db"], 3) == ["api", "core", "ui"];
    assert dependency_closure(g, "ui") == ["api", "auth", "core", "db"];
}

test "diamond impact adversarial" {
    g = load_module_graph(
        ["hub", "left", "right", "sink"],
        [("hub", "left"), ("hub", "right"), ("left", "sink"), ("right", "sink")],
    );
    assert impacted_modules(g, ["sink"], 2) == ["hub", "left", "right"];
}
