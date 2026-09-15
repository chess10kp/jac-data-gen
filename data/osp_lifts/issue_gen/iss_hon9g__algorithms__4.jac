"""MIT 6.006 Unit 5 graph traversals — hon9g/algorithms#4."""

node GNode {
    has cid: str;
}

edge GEdge {}

obj Graph {
    has nodes: dict[str, GNode] = {};
}

def _sorted_neighbors(here: GNode) -> list[GNode] {
    raw: list[GNode] = [];
    for ch in [here ->:GEdge:->][?:GNode] {
        raw.append(ch);
    }
    cids: list[str] = [];
    for nd in raw {
        cids.append(nd.cid);
    }
    cids = sorted(cids);
    out: list[GNode] = [];
    for sc in cids {
        for nd in raw {
            if nd.cid == sc {
                out.append(nd);
            }
        }
    }
    return out;
}

def build_graph(node_ids: list[str], edges: list[tuple[str, str]]) -> Graph {
    g = Graph();
    for nid in node_ids {
        nd = GNode(cid=nid);
        g.nodes[nid] = nd;
        root ++> nd;
    }
    for pair in edges {
        src_id = pair[0];
        dst_id = pair[1];
        if src_id in g.nodes and dst_id in g.nodes {
            src_nd = g.nodes[src_id];
            dst_nd = g.nodes[dst_id];
            src_nd +>:GEdge:+> dst_nd;
        }
    }
    return g;
}

walker BfsOrderWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        nbrs = _sorted_neighbors(here);
        visit nbrs;
    }
}

walker DfsPreWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        nbrs = _sorted_neighbors(here);
        visit :0: nbrs;
    }
}

walker DfsPostWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        nbrs = _sorted_neighbors(here);
        for nd in nbrs {
            sub = nd spawn DfsPostWalker(claimed=self.claimed);
            for cid in sub.order {
                self.order.append(cid);
            }
        }
        self.order.append(here.cid);
        print(here.cid);
    }
}

def bfs_order(g: Graph, start_id: str) -> list[str] {
    if start_id not in g.nodes {
        return [];
    }
    start_nd = g.nodes[start_id];
    w = start_nd spawn BfsOrderWalker();
    return w.order;
}

def dfs_preorder(g: Graph, start_id: str) -> list[str] {
    if start_id not in g.nodes {
        return [];
    }
    start_nd = g.nodes[start_id];
    w = start_nd spawn DfsPreWalker();
    return w.order;
}

def dfs_postorder(g: Graph, start_id: str) -> list[str] {
    if start_id not in g.nodes {
        return [];
    }
    start_nd = g.nodes[start_id];
    w = start_nd spawn DfsPostWalker();
    return w.order;
}
