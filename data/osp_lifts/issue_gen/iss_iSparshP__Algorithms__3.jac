"""iSparshP/Algorithms#3 — Adjacency-list graph BFS reach and neighbors."""

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
