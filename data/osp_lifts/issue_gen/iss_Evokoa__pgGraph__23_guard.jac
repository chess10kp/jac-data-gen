"""Guard: Evokoa/pgGraph#23."""

node GNode { has nid: str; }
edge Linked { has etype: str = ""; }
obj GraphStore {
    has nodes: dict[str, GNode] = {};
    has out_edges: dict[str, list[tuple[str, str]]] = {};
}

walker ShortestPath {
    has target: str = "";
    has edge_types: list[str] | None = None;
    has max_depth: int = 20;
    has best: list[str] | None = None;
    has depth: int = 0;
    has path: list[str] = [];
    has claimed: dict[str, bool] = {};
    has edge_index: dict[str, list[tuple[str, str]]] = {};
    can step with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        cur_path = self.path + [here.nid];
        if here.nid == self.target {
            if self.best is None or len(cur_path) < len(self.best) { self.best = cur_path; }
            disengage;
        }
        if len(cur_path) > self.max_depth { disengage; }
        for nxt in [here ->:Linked:->][?:GNode] {
            ok = False;
            for (dst, etype) in self.edge_index.get(here.nid, []) {
                if dst == nxt.nid and (self.edge_types is None or etype in self.edge_types) {
                    ok = True;
                }
            }
            if not ok { continue; }
            if nxt.nid in self.claimed { continue; }
            sub = nxt spawn ShortestPath(
                target=self.target, edge_types=self.edge_types, max_depth=self.max_depth,
                best=self.best, depth=self.depth + 1, path=cur_path, claimed=self.claimed,
                edge_index=self.edge_index,
            );
            self.best = sub.best;
            self.claimed = sub.claimed;
        }
    }
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has max_depth: int = 0;
    has depth: int = 0;
    has edge_types: list[str] | None = None;
    has edge_index: dict[str, list[tuple[str, str]]] = {};
    can step with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        if self.depth >= self.max_depth { disengage; }
        for nxt in [here ->:Linked:->][?:GNode] {
            ok = False;
            for (dst, etype) in self.edge_index.get(here.nid, []) {
                if dst == nxt.nid and (self.edge_types is None or etype in self.edge_types) {
                    ok = True;
                }
            }
            if not ok { continue; }
            if not (nxt.nid in self.claimed) {
                child = nxt spawn ReachWalk(
                    claimed=self.claimed, reached=self.reached, max_depth=self.max_depth,
                    depth=self.depth + 1, edge_types=self.edge_types, edge_index=self.edge_index,
                );
                self.claimed = child.claimed;
                self.reached = child.reached;
            }
        }
    }
}

def load_graph(nodes: list[str], edges: list[tuple[str, str, str]]) -> GraphStore {
    store = GraphStore();
    for nid in nodes {
        nd = GNode(nid=nid);
        root ++> nd;
        store.nodes[nid] = nd;
    }
    for (src, dst, etype) in edges {
        s = store.nodes.get(src, None);
        d = store.nodes.get(dst, None);
        if s is not None and d is not None {
            s +>:Linked(etype=etype):+> d;
            if src not in store.out_edges { store.out_edges[src] = []; }
            store.out_edges[src].append((dst, etype));
        }
    }
    return store;
}

def shortest_path(
    store: GraphStore,
    source: str,
    target: str,
    edge_types: list[str] | None = None,
    max_depth: int = 20,
) -> list[str] | None {
    s = store.nodes.get(source, None);
    if s is None or target not in store.nodes { return None; }
    if source == target { return [source]; }
    w = s spawn ShortestPath(
        target=target, edge_types=edge_types, max_depth=max_depth,
        best=None, depth=0, path=[], claimed={}, edge_index=store.out_edges,
    );
    return w.best;
}

def reachable_within(
    store: GraphStore,
    source: str,
    max_depth: int,
    edge_types: list[str] | None = None,
) -> list[str] {
    s = store.nodes.get(source, None);
    if s is None { return []; }
    w = s spawn ReachWalk(
        claimed={}, reached=[], max_depth=max_depth,
        depth=0, edge_types=edge_types, edge_index=store.out_edges,
    );
    return sorted(w.reached);
}

test "edge typed shortest path" {
    store = load_graph(
        ["a", "b", "c", "d"],
        [
            ("a", "b", "mentions"),
            ("b", "c", "mentions"),
            ("a", "d", "has_chunk"),
            ("d", "c", "mentions"),
        ],
    );
    assert shortest_path(store, "a", "c", ["mentions"]) == ["a", "b", "c"];
    assert shortest_path(store, "a", "c") == ["a", "b", "c"];
    assert reachable_within(store, "a", 2, ["mentions"]) == ["a", "b", "c"];
}
