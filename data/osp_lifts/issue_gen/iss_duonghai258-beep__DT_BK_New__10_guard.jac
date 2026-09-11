"""Guard: duonghai258-beep/DT.BK_New#10."""

node LayerNode { has name: str; has rank: int = 0; }
edge DependsOn {}

obj ArchGraph { has layers: dict[str, LayerNode] = {}; }

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with LayerNode entry {
        if here.name in self.visited { skip; }
        self.visited[here.name] = True;
        self.stack[here.name] = True;
        for nxt in [here ->:DependsOn:->][?:LayerNode] {
            if nxt.name in self.stack {
                self.errors.append((here.name, nxt.name));
            } else {
                if not (nxt.name in self.visited) { visit [nxt]; }
            }
        }
        self.stack[here.name] = False;
    }
}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with LayerNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:DependsOn:->][?:LayerNode];
    }
}

def load_arch_graph(
    layers: list[str],
    ranks: dict[str, int],
    deps: list[tuple[str, str]],
) -> ArchGraph {
    g = ArchGraph();
    for layer in layers {
        r = ranks.get(layer, 0);
        nd = LayerNode(name=layer, rank=r);
        root ++> nd;
        g.layers[layer] = nd;
    }
    for (src, dst) in deps {
        s = g.layers.get(src, None);
        d = g.layers.get(dst, None);
        if s is not None and d is not None { s +>:DependsOn:+> d; }
    }
    return g;
}

def detect_cycles(graph: ArchGraph) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(graph.layers.keys()) {
        if k in visited { continue; }
        nd = graph.layers[k];
        w = nd spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

def reverse_layer_violations(graph: ArchGraph) -> list[tuple[str, str]] {
    bad: list[tuple[str, str]] = [];
    for k in sorted(graph.layers.keys()) {
        src = graph.layers[k];
        for dst in [src ->:DependsOn:->][?:LayerNode] {
            if src.rank < dst.rank { bad.append((src.name, dst.name)); }
        }
    }
    return sorted(bad);
}

def upstream_closure(graph: ArchGraph, layer: str) -> list[str] {
    nd = graph.layers.get(layer, None);
    if nd is None { return []; }
    w = nd spawn UpstreamWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

test "clean architecture graph" {
    g = load_arch_graph(
        ["domain", "application", "infrastructure", "gui"],
        {"domain": 0, "application": 1, "infrastructure": 2, "gui": 3},
        [
            ("application", "domain"),
            ("infrastructure", "application"),
            ("gui", "application"),
        ],
    );
    assert detect_cycles(g) == [];
    assert reverse_layer_violations(g) == [];
    assert upstream_closure(g, "gui") == ["application", "domain", "gui"];
}

test "cycle detected" {
    g = load_arch_graph(["a", "b"], {"a": 0, "b": 1}, [("a", "b"), ("b", "a")]);
    assert detect_cycles(g) == [("b", "a")];
}

test "diamond upstream closure" {
    g = load_arch_graph(
        ["hub", "left", "right", "leaf"],
        {"hub": 3, "left": 2, "right": 2, "leaf": 1},
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    );
    assert upstream_closure(g, "hub") == ["hub", "leaf", "left", "right"];
}
