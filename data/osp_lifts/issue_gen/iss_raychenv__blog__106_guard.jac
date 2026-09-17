"""Graph BFS/DFS traversals — raychenv/blog#106 (pythonds adjacency / queue walk)."""

node Vertex {
    has vid: str;
    has label: str = "";
}

edge Arc {}

node GraphHub {
    has by_vid: dict[str, Vertex] = {};
}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Vertex entry {
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        self.order.append(here.vid);
        print("bfs", here.vid);
        kids: list[Vertex] = [];
        for ch in [here ->:Arc:->][?:Vertex] {
            kids.append(ch);
        }
        for i in range(len(kids) - 1, -1, -1) {
            visit :0: [kids[i]];
        }
    }
}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Vertex entry {
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        self.order.append(here.vid);
        print("dfs", here.vid);
        kids: list[Vertex] = [];
        for ch in [here ->:Arc:->][?:Vertex] {
            kids.append(ch);
        }
        for kid in kids {
            visit [kid];
        }
    }
}

walker BootWalker {
    has claimed: dict[str, bool] = {};

    can boot with Vertex entry {
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        print("blog_106_graph_osp_ready");
        disengage;
    }
}

def make_graph -> GraphHub {
    hub = GraphHub(by_vid={});
    root ++> hub;
    return hub;
}

def add_vertex(hub: GraphHub, vid: str, label: str = "") -> None {
    if vid in hub.by_vid {
        return;
    }
    v = Vertex(vid=vid, label=label);
    hub ++> v;
    hub.by_vid[vid] = v;
}

def add_edge(hub: GraphHub, src: str, dst: str) -> None {
    if src not in hub.by_vid {
        return;
    }
    if dst not in hub.by_vid {
        return;
    }
    a = hub.by_vid[src];
    b = hub.by_vid[dst];
    a +>:Arc:+> b;
}

def neighbors(hub: GraphHub, vid: str) -> list[str] {
    out: list[str] = [];
    if vid not in hub.by_vid {
        return out;
    }
    v = hub.by_vid[vid];
    for ch in [v ->:Arc:->][?:Vertex] {
        out.append(ch.vid);
    }
    return out;
}

def bfs_order(hub: GraphHub, start: str) -> list[str] {
    if start not in hub.by_vid {
        return [];
    }
    v0 = hub.by_vid[start];
    w = v0 spawn BfsWalker(claimed={}, order=[]);
    return w.order;
}

def dfs_preorder(hub: GraphHub, start: str) -> list[str] {
    if start not in hub.by_vid {
        return [];
    }
    v0 = hub.by_vid[start];
    w = v0 spawn DfsWalker(claimed={}, order=[]);
    return w.order;
}

with entry {
    hub = make_graph();
    add_vertex(hub, "boot");
    boot = hub.by_vid["boot"];
    boot spawn BootWalker(claimed={});
}

test "missing_start_empty" {
    hub = make_graph();
    add_vertex(hub, "a");
    assert (bfs_order(hub, "z") == []);
    assert (dfs_preorder(hub, "z") == []);
}

test "single_vertex_orders" {
    hub = make_graph();
    add_vertex(hub, "solo");
    assert (bfs_order(hub, "solo") == ["solo"]);
    assert (dfs_preorder(hub, "solo") == ["solo"]);
}

test "linear_bfs_dfs" {
    hub = make_graph();
    add_vertex(hub, "a");
    add_vertex(hub, "b");
    add_vertex(hub, "c");
    add_edge(hub, "a", "b");
    add_edge(hub, "b", "c");
    assert (bfs_order(hub, "a") == ["a", "b", "c"]);
    assert (dfs_preorder(hub, "a") == ["a", "b", "c"]);
}

test "branching_orders" {
    hub = make_graph();
    add_vertex(hub, "r");
    add_vertex(hub, "a");
    add_vertex(hub, "b");
    add_vertex(hub, "c");
    add_edge(hub, "r", "a");
    add_edge(hub, "r", "b");
    add_edge(hub, "a", "c");
    assert (bfs_order(hub, "r") == ["r", "a", "b", "c"]);
    assert (dfs_preorder(hub, "r") == ["r", "a", "c", "b"]);
}

test "neighbors_and_edge_guards" {
    hub = make_graph();
    add_vertex(hub, "x");
    add_vertex(hub, "y");
    add_edge(hub, "x", "y");
    add_edge(hub, "x", "missing");
    add_edge(hub, "missing", "y");
    nbrs = neighbors(hub, "x");
    assert (sorted(nbrs) == ["y"]);
    assert (neighbors(hub, "ghost") == []);
    add_vertex(hub, "x");
    assert (len(hub.by_vid) == 2);
}

test "cycle_revisit_once" {
    hub = make_graph();
    add_vertex(hub, "p");
    add_vertex(hub, "q");
    add_edge(hub, "p", "q");
    add_edge(hub, "q", "p");
    assert (bfs_order(hub, "p") == ["p", "q"]);
    assert (dfs_preorder(hub, "p") == ["p", "q"]);
}
