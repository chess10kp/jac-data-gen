"""guillipa1993/spring-security#1 — Build module dependency cycle detection."""

node Module {
    has name: str;
}

edge DependsOn {}

obj BuildGraph {
    has modules: dict[str, Module] = {};
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with Module entry {
        if here.name in self.visited { skip; }
        self.visited[here.name] = True;
        self.stack[here.name] = True;
        for dep in [here ->:DependsOn:->][?:Module] {
            if dep.name in self.stack {
                self.errors.append((here.name, dep.name));
            } else {
                if not (dep.name in self.visited) { visit [dep]; }
            }
        }
        self.stack[here.name] = False;
    }
}

def load_build_graph(
    modules: list[str],
    depends_edges: list[tuple[str, str]],
) -> BuildGraph {
    g = BuildGraph();
    for m in modules {
        nd = Module(name=m);
        root ++> nd;
        g.modules[m] = nd;
    }
    for (upstream, downstream) in depends_edges {
        u = g.modules.get(upstream, None);
        d = g.modules.get(downstream, None);
        if u is not None and d is not None { d +>:DependsOn:+> u; }
    }
    return g;
}

def detect_build_cycles(store: BuildGraph) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(store.modules.keys()) {
        if k in visited { continue; }
        nd = store.modules[k];
        w = nd spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

def build_order_depth(store: BuildGraph, module: str) -> int {
    nd = store.modules.get(module, None);
    if nd is None { return -1; }
    depth: dict[str, int] = {module: 0};
    frontier: list[Module] = [nd];
    best = 0;
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        cur_depth = depth[cur.name];
        for dep in [cur ->:DependsOn:->][?:Module] {
            nd2 = cur_depth + 1;
            if nd2 > best { best = nd2; }
            if not (dep.name in depth) or nd2 > depth[dep.name] {
                depth[dep.name] = nd2;
                frontier.append(dep);
            }
        }
    }
    return best;
}

test "acyclic build graph" {
    g = load_build_graph(
        ["core", "config", "web", "test"],
        [("core", "config"), ("config", "web"), ("core", "test")],
    );
    assert detect_build_cycles(g) == [];
    assert build_order_depth(g, "web") == 2;
}

test "cycle detection" {
    g2 = load_build_graph(["a", "b"], [("a", "b"), ("b", "a")]);
    assert detect_build_cycles(g2) == [("b", "a")];
}

test "diamond adversarial revisit" {
    g3 = load_build_graph(
        ["top", "left", "right", "bot"],
        [("top", "left"), ("top", "right"), ("left", "bot"), ("right", "bot")],
    );
    assert detect_build_cycles(g3) == [];
    assert build_order_depth(g3, "bot") == 2;
}
