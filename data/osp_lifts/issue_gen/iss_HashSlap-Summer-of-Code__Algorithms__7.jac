"""HashSlap-Summer-of-Code/Algorithms#7 — DFS traversal order via OSP walkers."""

node GNode { has cid: str; }

edge GEdge {}

walker DfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        kids: list[GNode] = [];
        for ch in [here ->:GEdge:->][?:GNode] {
            kids.append(ch);
        }
        idx = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx -= 1;
        }
    }
}

def materialize_adj(adj: dict[str, list[str]]) -> dict[str, GNode] {
    node_map: dict[str, GNode] = {};
    keys: list[str] = sorted(adj);
    for nid in keys {
        nd = GNode(cid=nid);
        root ++> nd;
        node_map[nid] = nd;
    }
    for src in sorted(adj) {
        src_nd = node_map[src] as GNode;
        nbrs: list[str] = adj[src];
        for dst in nbrs {
            if dst in node_map {
                dst_nd = node_map[dst] as GNode;
                src_nd +>:GEdge:+> dst_nd;
            }
        }
    }
    return node_map;
}

def dfs_traversal(adj: dict[str, list[str]], start: str) -> list[str] {
    if start not in adj {
        return [];
    }
    node_map = materialize_adj(adj);
    start_nd = node_map[start] as GNode;
    w = start_nd spawn DfsWalk();
    return w.order;
}

walker DemoPrint {
    can boot with Root entry {
        sample: dict[str, list[str]] = {
            "a": ["b", "c"],
            "b": ["d"],
            "c": ["d"],
            "d": []
        };
        ord_list = dfs_traversal(sample, "a");
        for item in ord_list {
            print(item);
        }
    }
}

with entry {
    root spawn DemoPrint();
}
