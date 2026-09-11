"""Guard: iSparshP/Algorithms#3."""

obj AdjGraph {
    has verts: dict[str, Vertex] = {};
}

node Vertex { has vid: str; }
edge Adj {}

walker BfsWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Vertex entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        self.reached.append(here.vid);
        visit [->:Adj:->];
    }
}

def load_adj_graph(vertices: list[str], edges: list[tuple[str, str]]) -> AdjGraph {
    g = AdjGraph();
    for v in vertices {
        if v not in g.verts {
            nd = Vertex(vid=v);
            root ++> nd;
            g.verts[v] = nd;
        }
    }
    for (src, dst) in edges {
        s = g.verts.get(src, None);
        d = g.verts.get(dst, None);
        if s is not None and d is not None { s +>:Adj:+> d; }
    }
    return g;
}

def bfs_reach(g: AdjGraph, start: str) -> list[str] {
    anchor = g.verts.get(start, None);
    if anchor is None { return []; }
    w = anchor spawn BfsWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def adjacent_to(g: AdjGraph, vertex_id: str) -> list[str] {
    anchor = g.verts.get(vertex_id, None);
    if anchor is None { return []; }
    out: list[str] = [];
    for nxt in [anchor ->:Adj:->][?:Vertex] { out.append(nxt.vid); }
    return sorted(out);
}

test "bfs reach on adjacency list" {
    g = load_adj_graph(
        ["1", "2", "3", "4"],
        [("1", "2"), ("1", "3"), ("2", "4")],
    );
    assert adjacent_to(g, "1") == ["2", "3"];
    assert bfs_reach(g, "1") == ["1", "2", "3", "4"];
}

test "diamond adversarial bfs reach" {
    g = load_adj_graph(
        ["hub", "left", "right", "leaf"],
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    );
    assert bfs_reach(g, "hub") == ["hub", "leaf", "left", "right"];
}

test "cycle graph reach and neighbors" {
    g = load_adj_graph(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert adjacent_to(g, "b") == ["c"];
    assert bfs_reach(g, "a") == ["a", "b", "c"];
}

test "unknown vertex tolerant" {
    g = load_adj_graph(["solo"], []);
    assert bfs_reach(g, "missing") == [];
    assert adjacent_to(g, "missing") == [];
}
