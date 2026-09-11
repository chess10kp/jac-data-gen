"""J-o-n-a-t-h-a-n-M-u-e-l-l-e-r/lattice#17 — Tarjan strongly-connected components."""

node GraphNode {
    has nid: str;
}

edge Rel {}

obj GraphStore {
    has nodes: dict[str, GraphNode] = {};
}

walker ForwardReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with GraphNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        visit [->:Rel:->][?:GraphNode];
    }
}

walker ReverseReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with GraphNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        visit [<-:Rel:<-][?:GraphNode];
    }
}

def load_graph(nodes: list[str], edges: list[tuple[str, str]]) -> GraphStore {
    g = GraphStore();
    for n in nodes {
        nd = GraphNode(nid=n);
        root ++> nd;
        g.nodes[n] = nd;
    }
    for (u, v) in edges {
        a = g.nodes.get(u, None);
        b = g.nodes.get(v, None);
        if a is not None and b is not None { a +>:Rel:+> b; }
    }
    return g;
}

def _forward(store: GraphStore, start_id: str) -> list[str] {
    nd = store.nodes.get(start_id, None);
    if nd is None { return []; }
    w = nd spawn ForwardReach(claimed={}, reached=[]);
    return w.reached;
}

def _reverse(store: GraphStore, start_id: str) -> list[str] {
    nd = store.nodes.get(start_id, None);
    if nd is None { return []; }
    w = nd spawn ReverseReach(claimed={}, reached=[]);
    return w.reached;
}

def strongly_connected_components(store: GraphStore) -> list[list[str]] {
    assigned: dict[str, bool] = {};
    comps: list[list[str]] = [];
    for n in sorted(store.nodes.keys()) {
        if n in assigned { continue; }
        fwd = _forward(store, n);
        rev = _reverse(store, n);
        rev_set: dict[str, bool] = {};
        for r in rev { rev_set[r] = True; }
        comp: list[str] = [];
        for m in fwd {
            if rev_set.get(m, False) {
                comp.append(m);
                assigned[m] = True;
            }
        }
        comps.append(sorted(comp));
    }
    for i in range(len(comps)) {
        for j in range(i + 1, len(comps)) {
            li = len(comps[i]);
            lj = len(comps[j]);
            do_swap = False;
            if li > lj { do_swap = True; }
            elif li == lj and comps[i][0] > comps[j][0] { do_swap = True; }
            if do_swap {
                tmp = comps[i];
                comps[i] = comps[j];
                comps[j] = tmp;
            }
        }
    }
    return comps;
}

def shortest_cycle_path(store: GraphStore, component: list[str]) -> list[str] {
    if len(component) < 2 { return list(component); }
    start = sorted(component)[0];
    w = _forward(store, start);
    for m in w {
        if m == start { continue; }
        bw = _forward(store, m);
        for b in bw {
            if b == start {
                return [start, m, start];
            }
        }
    }
    return [start];
}
