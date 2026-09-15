"""rayhuang2006/asymptote#25 — DFS/BFS adjacency traversal → O(V + E)."""

node GNode {
    has cid: str;
    has nbrs: list[str] = [];
}

edge GEdge {}

walker DfsCollect {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has node_ref: dict[str, GNode] = {};

    can step with GNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print("dfs", here.cid);
        idx: int = len(here.nbrs) - 1;
        while idx >= 0 {
            dst_id: str = here.nbrs[idx];
            if dst_id in self.node_ref {
                ch: GNode = self.node_ref[dst_id];
                visit :0: [ch];
            }
            idx -= 1;
        }
    }
}

walker BfsDepth {
    has claimed: dict[str, bool] = {};
    has depths: dict[str, int] = {};
    has node_ref: dict[str, GNode] = {};

    can step with GNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if not (here.cid in self.depths) {
            self.depths[here.cid] = 0;
        }
        cur: int = self.depths[here.cid];
        print("bfs", here.cid, cur);
        for dst_id in here.nbrs {
            if dst_id in self.node_ref {
                ch: GNode = self.node_ref[dst_id];
                if not (ch.cid in self.depths) {
                    self.depths[ch.cid] = cur + 1;
                }
                if not (ch.cid in self.claimed) {
                    visit [ch];
                }
            }
        }
    }
}

def ensure_in_store(store: dict[str, GNode], cid: str) -> GNode {
    if cid in store {
        return store[cid];
    }
    nd: GNode = GNode(cid=cid);
    root ++> nd;
    store[cid] = nd;
    return nd;
}

def build_from_adj(adj: dict[str, list[str]]) -> dict[str, GNode] {
    store: dict[str, GNode] = {};
    for src in adj {
        ensure_in_store(store, src);
        nd: GNode = store[src];
        nd.nbrs = adj[src];
        for dst in nd.nbrs {
            ensure_in_store(store, dst);
        }
    }
    for src in adj {
        s: GNode = store[src];
        for dst in s.nbrs {
            s +>:GEdge:+> store[dst];
        }
    }
    return store;
}

def parse_edges(raw: list[tuple[str, str]]) -> dict[str, list[str]] {
    adj: dict[str, list[str]] = {};
    for pair in raw {
        src: str = pair[0];
        dst: str = pair[1];
        if not (src in adj) {
            lst: list[str] = [];
            adj[src] = lst;
        }
        adj[src].append(dst);
        if not (dst in adj) {
            lst2: list[str] = [];
            adj[dst] = lst2;
        }
    }
    return adj;
}

def dfs_nodes(adj: dict[str, list[str]], start: str) -> list[str] {
    if not (start in adj) {
        return [];
    }
    store: dict[str, GNode] = build_from_adj(adj);
    w: DfsCollect = store[start] spawn DfsCollect(
        claimed={}, order=[], node_ref=store
    );
    print("dfs_order", w.order);
    return w.order;
}

def bfs_depths(adj: dict[str, list[str]], start: str) -> dict[str, int] {
    if not (start in adj) {
        return {};
    }
    store: dict[str, GNode] = build_from_adj(adj);
    w: BfsDepth = store[start] spawn BfsDepth(claimed={}, depths={}, node_ref=store);
    print("bfs_depths", w.depths);
    return w.depths;
}

def complexity_tag(adj: dict[str, list[str]]) -> str {
    v: int = len(adj);
    e: int = 0;
    for src in adj {
        e += len(adj[src]);
    }
    print("complexity", v, e);
    return "O(V + E)";
}

test "dfs_linear" {
    adj: dict[str, list[str]] = {"a": ["b"], "b": ["c"], "c": []};
    got: list[str] = dfs_nodes(adj, "a");
    assert (got == ["a", "b", "c"]);;
}

test "dfs_diamond_adversarial" {
    adj: dict[str, list[str]] = {
        "r": ["a", "b"],
        "a": ["t"],
        "b": ["t"],
        "t": []
    };
    got: list[str] = dfs_nodes(adj, "r");
    assert (got == ["r", "a", "t", "b"]);;
}

test "dfs_cycle_once" {
    adj: dict[str, list[str]] = {"a": ["b"], "b": ["c"], "c": ["a"]};
    got: list[str] = dfs_nodes(adj, "a");
    assert (len(got) == 3);;
    sg: list[str] = sorted(got);
    assert (sg == ["a", "b", "c"]);;
}

test "bfs_depths_diamond" {
    adj: dict[str, list[str]] = {
        "r": ["a", "b"],
        "a": ["t"],
        "b": ["t"],
        "t": []
    };
    got: dict[str, int] = bfs_depths(adj, "r");
    assert (got["r"] == 0);;
    assert (got["a"] == 1);;
    assert (got["b"] == 1);;
    assert (got["t"] == 2);;
}

test "missing_start_empty" {
    adj: dict[str, list[str]] = {"a": []};
    assert (dfs_nodes(adj, "z") == []);;
    assert (bfs_depths(adj, "z") == {});;
}

test "complexity_tag" {
    adj: dict[str, list[str]] = {"a": ["b"], "b": ["c"], "c": []};
    tag: str = complexity_tag(adj);
    assert (tag == "O(V + E)");;
}
