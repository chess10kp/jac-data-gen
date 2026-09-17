"""Depth-first search over an adjacency-list graph.

Lift of HashSlap-Summer-of-Code/Algorithms#7 (recursive DFS printing
traversal order) to idiomatic Jac OSP: GNode nodes, typed E edges,
claim-map + skip cycle policy, and a public dfs() facade.
"""

node GNode {
    has id: str;
    has weight: int = 0;
}

edge E;

# ---- graph construction (public API) ----

def add_node(store: dict[str, GNode], nid: str, weight: int = 0) -> GNode {
    if nid in store {
        return store[nid];
    }
    nd = GNode(id=nid, weight=weight);
    root ++> nd;
    store[nid] = nd;
    return nd;
}

def connect(store: dict[str, GNode], src: str, dst: str) -> None {
    if src not in store or dst not in store {
        return;
    }
    store[src] +>:E:+> store[dst];
}

def get(store: dict[str, GNode], nid: str) -> GNode | None {
    if nid in store {
        return store[nid];
    }
    return None;
}

# ---- recursive DFS (public facade, mirrors dfs.cpp traversal order) ----

def dfs_visit(cur: GNode, claimed: dict[str, bool], order: list[str]) -> None {
    claimed[cur.id] = True;
    order.append(cur.id);
    kids: list[GNode] = [cur ->:E:->];
    for k in kids {
        if k.id in claimed {
            continue;
        }
        dfs_visit(k, claimed, order);
    }
}

def dfs(graph_root: GNode) -> list[str] {
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    dfs_visit(graph_root, claimed, order);
    return order;
}

# ---- walker formulation of the same traversal ----

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        self.order.append(here.id);
        visit [here ->:E:->];
    }
}

def run_dfs(store: dict[str, GNode], start_id: str) -> list[str] {
    if start_id not in store {
        print("unknown start id: " + start_id);
        return [];
    }
    start = store[start_id];
    wk = start spawn DfsWalker(claimed={}, order=[]);
    print("dfs order: " + str(wk.order));
    return wk.order;
}
