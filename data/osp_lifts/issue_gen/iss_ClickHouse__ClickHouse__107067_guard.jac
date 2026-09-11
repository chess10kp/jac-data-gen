"""Guard: ClickHouse/ClickHouse#107067."""

obj SearchGraph {
    has nodes: dict[str, Node] = {};
    has edges: list[tuple[str, str, float]] = [];
}

node Node { has nid: str; }
edge Weighted { has w: float = 1.0; }

def load_search_graph(
    nodes: list[str],
    edges: list[tuple[str, str, float]],
) -> SearchGraph {
    g = SearchGraph();
    for nid in nodes {
        if nid not in g.nodes {
            n = Node(nid=nid);
            root ++> n;
            g.nodes[nid] = n;
        }
    }
    g.edges = edges;
    for (src, dst, weight) in edges {
        a = g.nodes.get(src, None);
        b = g.nodes.get(dst, None);
        if a is not None and b is not None { a +>:Weighted(w=weight):+> b; }
    }
    return g;
}

def shortest_costs(g: SearchGraph, start: str) -> dict[str, float] {
    if start not in g.nodes { return {}; }
    settled: dict[str, float] = {start: 0.0};
    rounds = len(g.nodes);
    for _ in range(rounds) {
        for (src, dst, w) in g.edges {
            if src not in settled { continue; }
            cand = settled[src] + w;
            old = settled.get(dst, None);
            if old is None or cand < old { settled[dst] = cand; }
        }
    }
    out: dict[str, float] = {};
    for k in sorted(settled.keys()) { out[k] = settled[k]; }
    return out;
}

def improved_nodes(g: SearchGraph, start: str) -> list[str] {
    return sorted(shortest_costs(g, start).keys());
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has on_stack: dict[str, bool] = {};
    has found: bool = False;

    can step with Node entry {
        if self.found { disengage; }
        if here.nid in self.on_stack {
            self.found = True;
            disengage;
        }
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.on_stack[here.nid] = True;
        visit [->:Weighted:->] else {
            del self.on_stack[here.nid];
            disengage;
        };
    }
}

def has_cycle(g: SearchGraph) -> bool {
    for nid in sorted(g.nodes.keys()) {
        w = g.nodes[nid] spawn CycleProbe(claimed={}, on_stack={}, found=False);
        if w.found { return True; }
    }
    return False;
}

test "settled refutation finds shorter detour" {
    g = load_search_graph(
        ["a", "b", "c", "d"],
        [("a", "b", 1.0), ("b", "c", 2.0), ("a", "d", 5.0), ("d", "c", 1.0)],
    );
    assert shortest_costs(g, "a") == {"a": 0.0, "b": 1.0, "c": 3.0, "d": 5.0};
}

test "cyclic graph still improves from seed" {
    g = load_search_graph(
        ["x", "y", "z"],
        [("x", "y", 1.0), ("y", "z", 1.0), ("z", "x", 1.0)],
    );
    assert has_cycle(g) is True;
    assert shortest_costs(g, "x")["y"] == 1.0;
}

test "diamond converges without path explosion" {
    g = load_search_graph(
        ["s", "m", "t1", "t2"],
        [("s", "t1", 4.0), ("s", "t2", 2.0), ("t2", "m", 1.0), ("m", "t1", 1.0)],
    );
    assert shortest_costs(g, "s")["t1"] == 4.0;
}
