"""gHashTag/t27#3541 — breadth-first traversal over an undirected adjacency graph."""

node Vertex {
    has cid: str;
    has vid: int = 0;
}

node GraphHub {
    has vertex_count: int = 0;
    has by_vid: dict[int, Vertex] = {};
}

edge Neighbor {}

node BFSOutcome {
    has order: list[int] = [];
    has distance: list[int] = [];
}

walker BFSWalker {
    has claimed: dict[str, bool] = {};
    has order: list[int] = [];
    has distance: list[int] = [];
    has dist_map: dict[str, int] = {};

    can step with Vertex entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        hop: int = self.dist_map[here.cid];
        self.order.append(here.vid);
        self.distance.append(hop);
        print("bfs", here.vid, hop);
        nbs: list[Vertex] = [here ->:Neighbor:->][?:Vertex];
        for nb in nbs {
            nb_key: str = nb.cid;
            if nb_key not in self.claimed {
                if nb_key not in self.dist_map {
                    self.dist_map[nb_key] = hop + 1;
                    visit [nb];
                }
            }
        }
    }
}

def init(vertex_count: int) -> GraphHub {
    hub = GraphHub(vertex_count=vertex_count);
    root ++> hub;
    for i in range(0, vertex_count) {
        cid: str = str(i);
        nd = Vertex(cid=cid, vid=i);
        hub ++> nd;
        hub.by_vid[i] = nd;
    }
    return hub;
}

def add_edge(graph: GraphHub, from_id: int, to_id: int) -> None {
    a = graph.by_vid[from_id];
    b = graph.by_vid[to_id];
    a +>:Neighbor:+> b;
    b +>:Neighbor:+> a;
}

def traverse(graph: GraphHub, start: int) -> BFSOutcome {
    if start < 0 or start >= graph.vertex_count {
        empty_order: list[int] = [];
        empty_dist: list[int] = [];
        return BFSOutcome(order=empty_order, distance=empty_dist);
    }
    start_nd = graph.by_vid[start];
    dist0: dict[str, int] = {};
    sk: str = str(start);
    dist0[sk] = 0;
    claimed0: dict[str, bool] = {};
    order0: list[int] = [];
    dist_list0: list[int] = [];
    w = start_nd spawn BFSWalker(
        claimed=claimed0,
        order=order0,
        distance=dist_list0,
        dist_map=dist0
    );
    return BFSOutcome(order=w.order, distance=w.distance);
}

def deinit(graph: GraphHub) -> None {
    cleared: dict[int, Vertex] = {};
    graph.by_vid = cleared;
    graph.vertex_count = 0;
}
