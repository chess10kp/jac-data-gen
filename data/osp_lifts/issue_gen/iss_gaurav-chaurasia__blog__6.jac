"""gaurav-chaurasia/blog#6 — Graph BFS reachability and path queries."""

node Vertex {
    has vid: str;
}

edge Adjacent {}

obj GraphStore {
    has verts: dict[str, Vertex] = {};
}

walker BfsWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Vertex entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        self.found.append(here.vid);
        visit [->:Adjacent:->][?:Vertex];
    }
}

def load_graph(
    node_ids: list[str],
    edges: list[tuple[str, str]],
) -> GraphStore {
    g = GraphStore();
    for nid in node_ids {
        nd = Vertex(vid=nid);
        root ++> nd;
        g.verts[nid] = nd;
    }
    for (a, b) in edges {
        va = g.verts.get(a, None);
        vb = g.verts.get(b, None);
        if va is not None and vb is not None {
            va +>:Adjacent:+> vb;
            vb +>:Adjacent:+> va;
        }
    }
    return g;
}

def bfs_reachable(store: GraphStore, start: str) -> list[str] {
    nd = store.verts.get(start, None);
    if nd is None { return []; }
    w = nd spawn BfsWalk(claimed={});
    return sorted(w.found);
}

def has_path(store: GraphStore, src: str, dst: str) -> bool {
    reach = bfs_reachable(store, src);
    for vid in reach {
        if vid == dst { return True; }
    }
    return False;
}

def component_size(store: GraphStore, start: str) -> int {
    return len(bfs_reachable(store, start));
}
