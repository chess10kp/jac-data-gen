"""burner-agent/agent-tools#67 — graph BFS/DFS traversal lift."""

node GNode {
    has cid: str;
    has label: str = "";
}

edge GEdge {
    has weight: int = 1;
}

obj GraphHandle {
    has directed: bool = True;
}

walker BfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        kids: list[GNode] = [here ->:GEdge:->][?:GNode];
        sorted_kids: list[GNode] = _sort_nodes_by_cid(kids);
        for ch in sorted_kids {
            if ch.cid not in self.claimed {
                visit [ch];
            }
        }
    }
}

walker DfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        kids: list[GNode] = [here ->:GEdge:->][?:GNode];
        sorted_kids: list[GNode] = _sort_nodes_by_cid(kids);
        idx: int = len(sorted_kids) - 1;
        while idx >= 0 {
            ch = sorted_kids[idx];
            if ch.cid not in self.claimed {
                visit :0: [ch];
            }
            idx -= 1;
        }
    }
}

def _sort_nodes_by_cid(nodes: list[GNode]) -> list[GNode] {
    cids: list[str] = [];
    out: list[GNode] = [];
    for nd in nodes {
        cids.append(nd.cid);
    }
    cids = sorted(cids);
    for cid in cids {
        for nd in nodes {
            if nd.cid == cid {
                out.append(nd);
            }
        }
    }
    return out;
}

def _node_by_cid(cid: str) -> GNode | None {
    for nd in [root-->] {
        if nd.cid == cid {
            return nd;
        }
    }
    return None;
}

def create_graph(directed: bool = True) -> GraphHandle {
    return GraphHandle(directed=directed);
}

def add_node(store: GraphHandle, node_id: str, label: str = "") -> bool {
    if _node_by_cid(node_id) is not None {
        return False;
    }
    nd = GNode(cid=node_id, label=label);
    root ++> nd;
    return True;
}

def add_edge(store: GraphHandle, src: str, dst: str, weight: int = 1) -> bool {
    src_nd = _node_by_cid(src);
    dst_nd = _node_by_cid(dst);
    if src_nd is None or dst_nd is None {
        return False;
    }
    src_nd +>:GEdge(weight=weight):+> dst_nd;
    if not store.directed {
        dst_nd +>:GEdge(weight=weight):+> src_nd;
    }
    return True;
}

def bfs_order(store: GraphHandle, start: str) -> list[str] {
    nd = _node_by_cid(start);
    if nd is None {
        return [];
    }
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    w = nd spawn BfsWalk(claimed=claimed, order=order);
    print({"algo": "bfs", "order": w.order});
    return w.order;
}

def dfs_order(store: GraphHandle, start: str) -> list[str] {
    nd = _node_by_cid(start);
    if nd is None {
        return [];
    }
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    w = nd spawn DfsWalk(claimed=claimed, order=order);
    print({"algo": "dfs", "order": w.order});
    return w.order;
}

test "bfs_diamond_sorted" {
    g = create_graph(directed=True);
    add_node(g, "A", "");
    add_node(g, "B", "");
    add_node(g, "C", "");
    add_node(g, "D", "");
    add_edge(g, "A", "B", 1);
    add_edge(g, "A", "C", 1);
    add_edge(g, "B", "D", 1);
    add_edge(g, "C", "D", 1);
    got = bfs_order(g, "A");
    assert got == ["A", "B", "C", "D"];
}

test "dfs_adversarial_diamond_revisit" {
    g = create_graph(directed=True);
    add_node(g, "A", "");
    add_node(g, "B", "");
    add_node(g, "C", "");
    add_node(g, "D", "");
    add_edge(g, "A", "B", 1);
    add_edge(g, "B", "D", 1);
    add_edge(g, "A", "C", 1);
    add_edge(g, "C", "D", 1);
    add_edge(g, "B", "C", 1);
    got = dfs_order(g, "A");
    assert got == ["A", "B", "C", "D"];
}

test "unknown_start_empty" {
    g = create_graph(directed=True);
    add_node(g, "A", "");
    assert bfs_order(g, "missing") == [];
    assert dfs_order(g, "missing") == [];
}

test "cycle_bfs_once_each" {
    g = create_graph(directed=True);
    add_node(g, "a", "");
    add_node(g, "b", "");
    add_node(g, "c", "");
    add_edge(g, "a", "b", 1);
    add_edge(g, "b", "c", 1);
    add_edge(g, "c", "a", 1);
    got = bfs_order(g, "a");
    assert got == ["a", "b", "c"];
}

test "undirected_bfs_both_ways" {
    g = create_graph(directed=False);
    add_node(g, "X", "");
    add_node(g, "Y", "");
    add_edge(g, "X", "Y", 1);
    got = bfs_order(g, "Y");
    assert got == ["Y", "X"];
}

test "duplicate_add_node_rejected" {
    g = create_graph(directed=True);
    assert add_node(g, "n1", "one") is True;
    assert add_node(g, "n1", "dup") is False;
}
