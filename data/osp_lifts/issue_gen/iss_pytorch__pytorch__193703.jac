"""pytorch/pytorch#193703 — TTIR shared-subgraph access reach with cycle guard."""

obj IrGraph {
    has nodes: dict[int, IrNode] = {};
}

node IrNode { has nid: int; }
edge DataFlow {}

walker AccessWalk {
    has claimed: dict[int, bool] = {};
    has reached: list[int] = [];

    can step with IrNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        visit [->:DataFlow:->] else { disengage; };
    }
}

def load_ir_graph(edges: list[tuple[int, int]]) -> IrGraph {
    g = IrGraph();
    for (src, dst) in edges {
        for nid in [src, dst] {
            if nid not in g.nodes {
                nd = IrNode(nid=nid);
                root ++> nd;
                g.nodes[nid] = nd;
            }
        }
        s = g.nodes[src];
        d = g.nodes[dst];
        s +>:DataFlow:+> d;
    }
    return g;
}

def access_reach(g: IrGraph, start: int) -> list[int] {
    anchor = g.nodes.get(start, None);
    if anchor is None { return []; }
    w = anchor spawn AccessWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def param_touch_count(g: IrGraph, start: int, param_idx: int) -> int {
    anchor = g.nodes.get(start, None);
    if anchor is None { return 0; }
    w = anchor spawn AccessWalk(claimed={}, reached=[]);
    cnt = 0;
    for nid in w.reached {
        if nid == param_idx { cnt += 1; }
    }
    return cnt if cnt <= 1 else 2;
}
