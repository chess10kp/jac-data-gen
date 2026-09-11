"""eugenemalaschuk-source/arch-linter-net#502 — Benchmark graph shape reachability."""

obj ShapeGraph { has nodes: dict[str, ShapeNode] = {}; }
node ShapeNode { has nid: str; }
edge Depends {}

def load_shape_graph(
    nodes: list[str],
    edges: list[tuple[str, str]],
) -> ShapeGraph {
    g = ShapeGraph();
    for n in nodes {
        if n not in g.nodes {
            nd = ShapeNode(nid=n);
            root ++> nd;
            g.nodes[n] = nd;
        }
    }
    for (src, dst) in edges {
        a = g.nodes.get(src, None);
        b = g.nodes.get(dst, None);
        if a is not None and b is not None { a +>:Depends:+> b; }
    }
    return g;
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with ShapeNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.hits.append(here.nid);
        visit [->:Depends:->][?:ShapeNode];
    }
}

def reachable_from(g: ShapeGraph, start: str) -> list[str] {
    nd = g.nodes.get(start, None);
    if nd is None { return []; }
    w = nd spawn ReachWalk(claimed={}, hits=[]);
    return sorted(w.hits);
}

def shape_stats(g: ShapeGraph, starts: list[str]) -> dict[str, int] {
    out: dict[str, int] = {};
    for s in sorted(starts) {
        out[s] = len(reachable_from(g, s));
    }
    return out;
}
