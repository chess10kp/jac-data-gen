node Vertex {
    has vid: str;
}
edge Dep {}
edge Contains {}

node GraphRoot {
    has verts: dict[str, Vertex] = {};
}

walker CollectVertices {
    has claimed: dict[str, bool] = {};
    has result: list[Vertex] = [];
    can start with GraphRoot entry {
        for kid in [here ->:Contains:->][?:Vertex] {
            visit :0: [kid];
        }
        if len([here ->:Contains:->][?:Vertex]) == 0 {
            disengage;
        }
    }
    can step with Vertex entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        self.result.append(here);
        print(here.vid);
        for nxt in [here ->:Dep:->][?:Vertex] {
            if nxt.vid not in self.claimed {
                visit :0: [nxt];
            }
        }
    }
}

def make_graph() -> GraphRoot {
    g = GraphRoot();
    return g;
}

def add_vertex(graph_root: GraphRoot, vid: str) -> Vertex {
    if vid in graph_root.verts {
        return graph_root.verts[vid];
    }
    v = Vertex(vid=vid);
    graph_root.verts[vid] = v;
    graph_root +>:Contains:+> v;
    return v;
}

def add_edge(graph_root: GraphRoot, src: str, dst: str) -> bool {
    # unknown-id tolerance
    if src not in graph_root.verts { return False; }
    if dst not in graph_root.verts { return False; }
    s: Vertex = graph_root.verts[src];
    d: Vertex = graph_root.verts[dst];
    s +>:Dep:+> d;
    return True;
}

def kahn_topological_sort(graph_root: GraphRoot) -> list[str] {
    # Kahn BFS in-degree algorithm
    indeg: dict[str, int] = {};
    adj: dict[str, list[str]] = {};
    for vid in graph_root.verts {
        indeg[vid] = 0;
        adj[vid] = [];
    }
    for vid in graph_root.verts {
        v: Vertex = graph_root.verts[vid];
        for nxt in [v ->:Dep:->][?:Vertex] {
            indeg[nxt.vid] = indeg[nxt.vid] + 1;
            adj[vid].append(nxt.vid);
        }
    }
    queue: list[str] = [];
    for vid in graph_root.verts {
        if indeg[vid] == 0 {
            queue.append(vid);
        }
    }
    queue = sorted(queue);
    result: list[str] = [];
    while len(queue) > 0 {
        cur: str = queue.pop(0);
        result.append(cur);
        for nb in adj[cur] {
            indeg[nb] = indeg[nb] - 1;
            if indeg[nb] == 0 {
                queue.append(nb);
            }
        }
        queue = sorted(queue);
    }
    if len(result) != len(graph_root.verts) {
        raise Exception("cycle detected");
    }
    return result;
}

def kahn_topological_sort_layers(graph_root: GraphRoot) -> list[list[str]] {
    indeg: dict[str, int] = {};
    adj: dict[str, list[str]] = {};
    for vid in graph_root.verts { indeg[vid] = 0; adj[vid] = []; }
    for vid in graph_root.verts {
        v: Vertex = graph_root.verts[vid];
        for nxt in [v ->:Dep:->][?:Vertex] {
            indeg[nxt.vid] = indeg[nxt.vid] + 1;
            adj[vid].append(nxt.vid);
        }
    }
    queue: list[str] = [];
    for vid in graph_root.verts { if indeg[vid] == 0 { queue.append(vid); } }
    queue = sorted(queue);
    layers: list[list[str]] = [];
    while len(queue) > 0 {
        cur_layer: list[str] = [];
        next_q: list[str] = [];
        for cur in queue {
            cur_layer.append(cur);
        }
        queue = [];
        for cur in cur_layer {
            for nb in adj[cur] {
                indeg[nb] = indeg[nb] - 1;
                if indeg[nb] == 0 { next_q.append(nb); }
            }
        }
        next_q = sorted(next_q);
        layers.append(sorted(cur_layer));
        queue = next_q;
    }
    total: int = 0;
    for lyr in layers { total = total + len(lyr); }
    if total != len(graph_root.verts) { raise Exception("cycle detected"); }
    return layers;
}

def has_cycle(graph_root: GraphRoot) -> bool {
    indeg: dict[str, int] = {};
    adj: dict[str, list[str]] = {};
    for vid in graph_root.verts { indeg[vid] = 0; adj[vid] = []; }
    for vid in graph_root.verts {
        v: Vertex = graph_root.verts[vid];
        for nxt in [v ->:Dep:->][?:Vertex] {
            indeg[nxt.vid] = indeg[nxt.vid] + 1;
            adj[vid].append(nxt.vid);
        }
    }
    queue: list[str] = [];
    for vid in graph_root.verts { if indeg[vid] == 0 { queue.append(vid); } }
    cnt: int = 0;
    while len(queue) > 0 {
        cur: str = queue.pop(0);
        cnt = cnt + 1;
        for nb in adj[cur] {
            indeg[nb] = indeg[nb] - 1;
            if indeg[nb] == 0 { queue.append(nb); }
        }
    }
    return cnt != len(graph_root.verts);
}

with entry {
    g = make_graph();
    add_vertex(g, "demo_a");
    add_vertex(g, "demo_b");
    add_edge(g, "demo_a", "demo_b");
    w = g spawn CollectVertices(claimed={}, result=[]);
    print(w.result);
    r = root spawn CollectVertices(claimed={}, result=[]);
    print(r.result);
    order = kahn_topological_sort(g);
    print(order);
}
