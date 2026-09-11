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
test "bfs reachability" {
    g = load_graph([1, 2, 3, 4, 5], [(1, 2), (1, 3), (2, 4), (3, 5)]);
    assert bfs_reachable(g, 1) == [2, 3, 4, 5];
    assert bfs_distance(g, 1, 5) == 2;
    assert out_neighbors(g, 1) == [2, 3];
}

test "diamond bfs revisit" {
    g = load_graph([0, 1, 2, 3], [(0, 1), (0, 2), (1, 3), (2, 3)]);
    assert bfs_reachable(g, 0) == [1, 2, 3];
}
