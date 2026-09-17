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
