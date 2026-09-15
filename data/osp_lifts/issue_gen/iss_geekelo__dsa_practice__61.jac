"""geekelo/dsa_practice#61 — adjacency-list graph BFS/DFS (hand-rolled lift)."""

node GNode {
    has nid: str;
}

edge Adj {}

obj GraphHandle {
    has graph_root: GNode;
    has nodes: dict[str, GNode] = {};
}

walker BfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can bfs_step with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        kids: list[GNode] = [];
        for ch in [here ->:Adj:->][?:GNode] {
            kids.append(ch);
        }
        kids = _sort_nodes_by_nid(kids);
        for ch in kids {
            if ch.nid not in self.claimed {
                visit [ch];
            }
        }
    }
}

walker DfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can dfs_step with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        kids: list[GNode] = [];
        for ch in [here ->:Adj:->][?:GNode] {
            kids.append(ch);
        }
        kids = _sort_nodes_by_nid(kids);
        for ch in kids {
            if ch.nid not in self.claimed {
                visit :0: [ch];
            }
        }
    }
}

walker DemoWalk {
    has claimed: dict[str, bool] = {};

    can demo_step with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.nid != "__root__" {
            print("visit " + here.nid);
        }
        kids: list[GNode] = [];
        for ch in [here ->:Adj:->][?:GNode] {
            kids.append(ch);
        }
        for ch in kids {
            if ch.nid not in self.claimed {
                visit [ch];
            }
        } else {
            disengage;
        }
    }
}

def _sort_nodes_by_nid(nodes: list[GNode]) -> list[GNode] {
    ids: list[str] = [];
    for nd in nodes {
        ids.append(nd.nid);
    }
    ids = sorted(ids);
    out: list[GNode] = [];
    for sid in ids {
        for nd in nodes {
            if nd.nid == sid {
                out.append(nd);
            }
        }
    }
    return out;
}

def _find_or_create(g: GraphHandle, nid: str) -> GNode {
    if nid in g.nodes {
        return g.nodes[nid];
    }
    nd: GNode = GNode(nid=nid);
    g.graph_root ++> nd;
    g.nodes[nid] = nd;
    return nd;
}

def new_graph -> GraphHandle {
    graph_root: GNode = GNode(nid="__root__");
    root ++> graph_root;
    g: GraphHandle = GraphHandle(graph_root=graph_root);
    return g;
}

def ensure_node(g: GraphHandle, node_id: str) {
    _find_or_create(g, node_id);
}

def add_undirected_edge(g: GraphHandle, a: str, b: str) {
    na: GNode = _find_or_create(g, a);
    nb: GNode = _find_or_create(g, b);
    na +>:Adj:+> nb;
    nb +>:Adj:+> na;
}

def neighbors(g: GraphHandle, node_id: str) -> list[str] {
    if node_id not in g.nodes {
        return [];
    }
    nd: GNode = g.nodes[node_id];
    out: list[str] = [];
    for ch in [nd ->:Adj:->][?:GNode] {
        out.append(ch.nid);
    }
    return sorted(out);
}

def bfs_order(g: GraphHandle, start: str) -> list[str] {
    if start not in g.nodes {
        return [];
    }
    start_node: GNode = g.nodes[start];
    w: BfsWalk = start_node spawn BfsWalk(claimed={}, order=[]);
    return w.order;
}

def dfs_order(g: GraphHandle, start: str) -> list[str] {
    if start not in g.nodes {
        return [];
    }
    start_node: GNode = g.nodes[start];
    w: DfsWalk = start_node spawn DfsWalk(claimed={}, order=[]);
    return w.order;
}

with entry {
    g: GraphHandle = new_graph();
    add_undirected_edge(g, "A", "B");
    add_undirected_edge(g, "B", "C");
    root spawn DemoWalk(claimed={});
}
