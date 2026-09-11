"""mtetno/devtools#6 — q2 subtree metric rollup (OSP lift)."""

obj MetricTree {
    has nodes: dict[str, MetricNode] = {};
}

node MetricNode {
    has nid: str;
    has value: int;
}

edge ChildOf {}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_nid: str = "";

    can step with MetricNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.nid != self.start_nid { self.reached.append(here.nid); }
        for ch in [here <-:ChildOf:<-] { visit [ch]; }
    }
}

def load_tree(
    nodes: list[tuple[str, int]],
    parent_edges: list[tuple[str, str]],
) -> MetricTree {
    g = MetricTree();
    for (nid, val) in nodes {
        n = MetricNode(nid=nid, value=val);
        root ++> n;
        g.nodes[nid] = n;
    }
    for (child, par) in parent_edges {
        c = g.nodes.get(child, None);
        p = g.nodes.get(par, None);
        if c is not None and p is not None { c +>:ChildOf:+> p; }
    }
    return g;
}

def descendant_ids(g: MetricTree, node_id: str) -> list[str] {
    anchor = g.nodes.get(node_id, None);
    if anchor is None { return []; }
    w = anchor spawn DescendantWalk(claimed={}, reached=[], start_nid=node_id);
    return sorted(w.reached);
}

def recursive_sum(g: MetricTree, node_id: str) -> int {
    anchor = g.nodes.get(node_id, None);
    if anchor is None { return 0; }
    w = anchor spawn DescendantWalk(claimed={}, reached=[], start_nid=node_id);
    total = anchor.value;
    for nid in w.reached {
        n = g.nodes.get(nid, None);
        if n is not None { total += n.value; }
    }
    return total;
}
