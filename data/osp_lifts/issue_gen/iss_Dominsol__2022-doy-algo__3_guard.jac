"""Dominsol/2022-doy-algo#3 — stack/queue DFS and BFS traversal."""

node GNode {
    has cid: str;
}

edge GEdge {}

obj GraphStore {
    has by_id: dict[str, GNode];
}

def make_graph() -> GraphStore {
    m: dict[str, GNode] = {};
    return GraphStore(by_id=m);
}

def get_or_create_node(store: GraphStore, node_id: str) -> GNode {
    if node_id in store.by_id {
        return store.by_id[node_id];
    }
    nd = GNode(cid=node_id);
    root ++> nd;
    store.by_id[node_id] = nd;
    return nd;
}

def sorted_out_neighbors(here: GNode) -> list[GNode] {
    kids: list[GNode] = [here ->:GEdge:->][?:GNode];
    ids: list[str] = [];
    for kid in kids {
        ids.append(kid.cid);
    }
    sids = sorted(ids);
    out: list[GNode] = [];
    for sid in sids {
        for kid in kids {
            if kid.cid == sid {
                out.append(kid);
            }
        }
    }
    return out;
}

def add_directed_edge(store: GraphStore, src_id: str, dst_id: str) -> None {
    src = get_or_create_node(store, src_id);
    dst = get_or_create_node(store, dst_id);
    kids: list[GNode] = [src ->:GEdge:->][?:GNode];
    found: bool = False;
    for ch in kids {
        if ch.cid == dst_id {
            found = True;
        }
    }
    if not found {
        src +>:GEdge:+> dst;
    }
}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        out = sorted_out_neighbors(here);
        n = len(out);
        i = n - 1;
        while i >= 0 {
            visit :0: [out[i]];
            i -= 1;
        }
    }
}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        out = sorted_out_neighbors(here);
        for kid in out {
            visit [kid];
        }
    }
}

def dfs_order(store: GraphStore, start_id: str) -> list[str] {
    if start_id not in store.by_id {
        return [];
    }
    start = store.by_id[start_id];
    w = start spawn DfsWalker();
    print("dfs_order", w.order);
    return w.order;
}

def bfs_order(store: GraphStore, start_id: str) -> list[str] {
    if start_id not in store.by_id {
        return [];
    }
    start = store.by_id[start_id];
    w = start spawn BfsWalker();
    print("bfs_order", w.order);
    return w.order;
}

with entry {
    demo = make_graph();
    add_directed_edge(demo, "1", "2");
    add_directed_edge(demo, "1", "3");
    add_directed_edge(demo, "2", "4");
    dfs_order(demo, "1");
    bfs_order(demo, "1");
}

test "dfs_chain_preorder" {
    g = make_graph();
    add_directed_edge(g, "1", "2");
    add_directed_edge(g, "2", "3");
    assert dfs_order(g, "1") == ["1", "2", "3"];
}

test "bfs_chain_level" {
    g = make_graph();
    add_directed_edge(g, "1", "2");
    add_directed_edge(g, "2", "3");
    assert bfs_order(g, "1") == ["1", "2", "3"];
}

test "diamond_revisit_adversarial" {
    g = make_graph();
    add_directed_edge(g, "a", "b");
    add_directed_edge(g, "a", "c");
    add_directed_edge(g, "b", "d");
    add_directed_edge(g, "c", "d");
    assert dfs_order(g, "a") == ["a", "b", "d", "c"];
    assert bfs_order(g, "a") == ["a", "b", "c", "d"];
}

test "unknown_start_tolerance" {
    g = make_graph();
    add_directed_edge(g, "x", "y");
    assert dfs_order(g, "missing") == [];
    assert bfs_order(g, "missing") == [];
}

test "self_loop_once" {
    g = make_graph();
    add_directed_edge(g, "solo", "solo");
    assert dfs_order(g, "solo") == ["solo"];
    assert bfs_order(g, "solo") == ["solo"];
}
