"""Guard: pytorch/pytorch#193703."""

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

test "linear ir access reach" {
    g = load_ir_graph([(0, 1), (1, 2), (2, 3)]);
    assert access_reach(g, 0) == [0, 1, 2, 3];
    assert param_touch_count(g, 0, 2) == 1;
}

test "diamond shared subgraph access" {
    g = load_ir_graph([(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)]);
    assert access_reach(g, 0) == [0, 1, 2, 3, 4];
    assert param_touch_count(g, 0, 3) == 1;
}

test "branch join reach" {
    g = load_ir_graph([(0, 1), (1, 2), (1, 3), (2, 4), (3, 4)]);
    assert access_reach(g, 0) == [0, 1, 2, 3, 4];
}

test "cycle terminates once per node" {
    g = load_ir_graph([(0, 1), (1, 2), (2, 0)]);
    assert access_reach(g, 0) == [0, 1, 2];
}

test "unknown start tolerant" {
    g = load_ir_graph([(0, 1)]);
    assert access_reach(g, 99) == [];
    assert param_touch_count(g, 99, 0) == 0;
}
