"""ClickHouse/ClickHouse#107067 — keyed recursive search (OSP lift)."""

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
