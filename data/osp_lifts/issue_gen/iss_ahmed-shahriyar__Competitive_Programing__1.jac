"""ahmed-shahriyar/Competitive_Programing#1 — Graph BFS reachability over adjacency lists."""

node GraphNode {
    has nid: int;
}

edge Adjacent {}

obj GraphStore {
    has nodes: dict[int, GraphNode] = {};
}

walker BfsWalk {
    has claimed: dict[int, bool] = {};
    has hits: list[int] = [];

    can step with GraphNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.hits.append(here.nid);
        visit [->:Adjacent:->][?:GraphNode];
    }
}

walker DistanceWalk {
    has target: int = 0;
    has claimed: dict[int, bool] = {};
    has depth: int = 0;
    has found: int = -1;

    can step with GraphNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.nid == self.target {
            self.found = self.depth;
            disengage;
        }
        self.depth += 1;
        visit [->:Adjacent:->][?:GraphNode];
    }
}

def load_graph(nodes: list[int], edges: list[tuple[int, int]]) -> GraphStore {
    g = GraphStore();
    for n in nodes {
        if n not in g.nodes {
            nd = GraphNode(nid=n);
            root ++> nd;
            g.nodes[n] = nd;
        }
    }
    for (u, v) in edges {
        a = g.nodes.get(u, None);
        b = g.nodes.get(v, None);
        if a is not None and b is not None { a +>:Adjacent:+> b; }
    }
    return g;
}

def bfs_reachable(g: GraphStore, start: int) -> list[int] {
    nd = g.nodes.get(start, None);
    if nd is None { return []; }
    w = nd spawn BfsWalk(claimed={}, hits=[]);
    out: list[int] = [];
    for h in w.hits {
        if h != start { out.append(h); }
    }
    return sorted(out);
}

def bfs_distance(g: GraphStore, start: int, target: int) -> int | None {
    if start not in g.nodes or target not in g.nodes { return None; }
    if start == target { return 0; }
    pending: list[tuple[int, int]] = [(start, 0)];
    claimed: dict[int, bool] = {start: True};
    while len(pending) > 0 {
        (cur, dist) = pending.pop(0);
        nd = g.nodes.get(cur, None);
        if nd is None { continue; }
        for nb in [nd ->:Adjacent:->][?:GraphNode] {
            if nb.nid == target { return dist + 1; }
            if nb.nid not in claimed {
                claimed[nb.nid] = True;
                pending.append((nb.nid, dist + 1));
            }
        }
    }
    return None;
}

def out_neighbors(g: GraphStore, node_id: int) -> list[int] {
    nd = g.nodes.get(node_id, None);
    if nd is None { return []; }
    return sorted([n.nid for n in [nd ->:Adjacent:->][?:GraphNode]]);
}
