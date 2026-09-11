"""fiedl/wingolfsplattform#129 — DAG parent-child + transitive reach."""

obj DagStore { has nodes: dict[str, DagNode] = {}; }
node DagNode { has nid: str; }
edge ChildOf {}

walker DescWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    can step with DagNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.hits.append(here.nid);
        visit [->:ChildOf:->][?:DagNode];
    }
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    can step with DagNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.chain.append(here.nid);
        parents = [here <-:ChildOf:<-][?:DagNode];
        if not parents { disengage; }
        pick = parents[0];
        for p in parents { if p.nid < pick.nid { pick = p; } }
        visit [pick];
    }
}

def load_dag(
    nodes: list[str],
    edges: list[tuple[str, str]],
) -> DagStore {
    g = DagStore();
    for nid in nodes {
        if nid not in g.nodes {
            nd = DagNode(nid=nid);
            root ++> nd;
            g.nodes[nid] = nd;
        }
    }
    for (parent, child) in edges {
        p = g.nodes.get(parent, None);
        c = g.nodes.get(child, None);
        if p is None or c is None { continue; }
        p +>:ChildOf:+> c;
    }
    return g;
}

def descendants(g: DagStore, node_id: str) -> list[str] {
    start = g.nodes.get(node_id, None);
    if start is None { return []; }
    w = start spawn DescWalk(claimed={}, hits=[]);
    return sorted(w.hits);
}

def ancestors(g: DagStore, node_id: str) -> list[str] {
    start = g.nodes.get(node_id, None);
    if start is None { return []; }
    w = start spawn AncestorWalk(claimed={}, chain=[]);
    return w.chain;
}

def reach(g: DagStore, src: str, dst: str) -> bool {
    start = g.nodes.get(src, None);
    if start is None { return False; }
    w = start spawn DescWalk(claimed={}, hits=[]);
    for nid in w.hits { if nid == dst { return True; } }
    return False;
}
