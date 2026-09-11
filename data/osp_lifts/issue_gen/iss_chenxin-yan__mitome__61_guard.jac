"""Guard: chenxin-yan/mitome#61."""

node Extension { has name: str; }
edge ExtDepends {}

obj ExtensionGraph {
    has extensions: dict[str, Extension] = {};
    has provides: dict[str, list[str]] = {};
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with Extension entry {
        if here.name in self.visited { skip; }
        self.visited[here.name] = True;
        self.stack[here.name] = True;
        for dep in [here <-:ExtDepends:<-][?:Extension] {
            if dep.name in self.stack {
                self.errors.append((here.name, dep.name));
            } else {
                if not (dep.name in self.visited) { visit [dep]; }
            }
        }
        self.stack[here.name] = False;
    }
}

walker DepCollect {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Extension entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [<-:ExtDepends:<-][?:Extension];
    }
}

def load_extension_graph(
    names: list[str],
    depends: list[tuple[str, str]],
    provides: dict[str, list[str]] | None = None,
) -> ExtensionGraph {
    g = ExtensionGraph();
    for name in names {
        nd = Extension(name=name);
        root ++> nd;
        g.extensions[name] = nd;
        g.provides[name] = list((provides or {}).get(name, []));
    }
    for (dep, ext) in depends {
        d = g.extensions.get(dep, None);
        e = g.extensions.get(ext, None);
        if d is not None and e is not None { d +>:ExtDepends:+> e; }
    }
    return g;
}

def detect_extension_cycles(graph: ExtensionGraph) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(graph.extensions.keys()) {
        if k in visited { continue; }
        w = graph.extensions[k] spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

def resolve_load_order(graph: ExtensionGraph) -> list[str] {
    indeg: dict[str, int] = {};
    rev: dict[str, list[str]] = {};
    for name in graph.extensions.keys() {
        indeg[name] = 0;
        rev[name] = [];
    }
    for (name, nd) in graph.extensions.items() {
        for dep in [nd <-:ExtDepends:<-][?:Extension] {
            indeg[name] += 1;
            rev[dep.name].append(name);
        }
    }
    frontier: list[str] = [];
    for name in sorted(graph.extensions.keys()) {
        if indeg[name] == 0 { frontier.append(name); }
    }
    order: list[str] = [];
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        order.append(cur);
        for nxt in sorted(rev.get(cur, [])) {
            indeg[nxt] -= 1;
            if indeg[nxt] == 0 { frontier.append(nxt); }
        }
        frontier = sorted(frontier);
    }
    return order if len(order) == len(graph.extensions) else [];
}

def transitive_dependencies(graph: ExtensionGraph, ext_id: str) -> list[str] {
    nd = graph.extensions.get(ext_id, None);
    if nd is None { return []; }
    w = nd spawn DepCollect(claimed={}, reached=[]);
    out: list[str] = [];
    for name in w.reached {
        if name != ext_id { out.append(name); }
    }
    return sorted(out);
}

test "extension load order" {
    g = load_extension_graph(
        ["browser", "scraper", "screenshot"],
        [("browser", "scraper"), ("browser", "screenshot")],
        {"browser": ["page"], "scraper": ["html"]},
    );
    assert resolve_load_order(g) == ["browser", "scraper", "screenshot"];
    assert transitive_dependencies(g, "screenshot") == ["browser"];
    assert detect_extension_cycles(g) == [];
}

test "extension cycle detected" {
    c = load_extension_graph(["a", "b"], [("a", "b"), ("b", "a")]);
    assert detect_extension_cycles(c) == [("b", "a")];
    assert resolve_load_order(c) == [];
}

test "diamond dependency collect" {
    g = load_extension_graph(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "leaf"),
            ("right", "leaf"),
        ],
    );
    assert transitive_dependencies(g, "leaf") == ["hub", "left", "right"];
}
