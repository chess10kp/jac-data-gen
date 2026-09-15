"""Graph traversal (BFS & DFS) — DH-YASSER/algorithms-practice#1."""

node GNode {
    has nid: str;
}

edge GEdge {}

def _sort_ids(ids: list[str]) -> list[str] {
    out: list[str] = [];
    for x in ids {
        out.append(x);
    }
    out.sort();
    return out;
}

def _get_or_create(nodes: dict[str, GNode], nid: str) -> GNode {
    if nid in nodes {
        return nodes[nid] as GNode;
    }
    nd = GNode(nid=nid);
    root ++> nd;
    nodes[nid] = nd;
    return nd;
}

def _build_from_adj(adj: dict[str, list[str]]) -> dict[str, GNode] {
    nodes: dict[str, GNode] = {};
    keys: list[str] = [];
    for k in adj {
        keys.append(k);
    }
    keys = _sort_ids(keys);
    for src in keys {
        _get_or_create(nodes, src);
        nbrs: list[str] = adj[src] as list[str];
        sorted_nbrs: list[str] = _sort_ids(nbrs);
        for dst in sorted_nbrs {
            dst_nd = _get_or_create(nodes, dst);
            src_nd = nodes[src] as GNode;
            src_nd +>:GEdge:+> dst_nd;
        }
    }
    return nodes;
}

def _sorted_children(here: GNode) -> list[GNode] {
    kids: list[GNode] = [];
    for ch in [here ->:GEdge:->][?:GNode] {
        kids.append(ch);
    }
    kid_ids: list[str] = [];
    for k in kids {
        kid_ids.append(k.nid);
    }
    kid_ids.sort();
    ordered: list[GNode] = [];
    for kid_nid in kid_ids {
        for ch in kids {
            if ch.nid == kid_nid {
                ordered.append(ch);
            }
        }
    }
    return ordered;
}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can bfs_step with GNode entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        print(here.nid);
        for ch in _sorted_children(here) {
            if ch.nid not in self.claimed {
                visit [ch];
            }
        }
    }
}

walker DfsIterWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can dfs_iter_step with GNode entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        print(here.nid);
        ordered: list[GNode] = _sorted_children(here);
        idx: int = len(ordered) - 1;
        while idx >= 0 {
            ch = ordered[idx];
            if ch.nid not in self.claimed {
                visit :0: [ch];
            }
            idx = idx - 1;
        }
    }
}

walker DfsRecWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can dfs_rec_step with GNode entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        print(here.nid);
        for ch in _sorted_children(here) {
            if ch.nid not in self.claimed {
                visit :0: [ch];
            }
        }
    }
}

def bfs(adj: dict[str, list[str]], start: str) -> list[str] {
    nodes: dict[str, GNode] = _build_from_adj(adj);
    if start not in nodes {
        empty: list[str] = [];
        return empty;
    }
    start_nd = nodes[start] as GNode;
    w = start_nd spawn BfsWalker(claimed={});
    return w.order;
}

def dfs_iterative(adj: dict[str, list[str]], start: str) -> list[str] {
    nodes: dict[str, GNode] = _build_from_adj(adj);
    if start not in nodes {
        empty: list[str] = [];
        return empty;
    }
    start_nd = nodes[start] as GNode;
    w = start_nd spawn DfsIterWalker(claimed={});
    return w.order;
}

def dfs_recursive(adj: dict[str, list[str]], start: str) -> list[str] {
    nodes: dict[str, GNode] = _build_from_adj(adj);
    if start not in nodes {
        empty: list[str] = [];
        return empty;
    }
    start_nd = nodes[start] as GNode;
    w = start_nd spawn DfsRecWalker(claimed={});
    return w.order;
}

test "bfs_linear_chain" {
    adj: dict[str, list[str]] = {
        "a": ["b"],
        "b": ["c"],
        "c": []
    };
    got = bfs(adj, "a");
    assert (got == ["a", "b", "c"]);;
}

test "dfs_iterative_branch_order" {
    adj: dict[str, list[str]] = {
        "a": ["b", "c"],
        "b": ["d"],
        "c": [],
        "d": []
    };
    got = dfs_iterative(adj, "a");
    assert (got == ["a", "b", "d", "c"]);;
}

test "dfs_recursive_branch_order" {
    adj: dict[str, list[str]] = {
        "a": ["b", "c"],
        "b": ["d"],
        "c": [],
        "d": []
    };
    got = dfs_recursive(adj, "a");
    assert (got == ["a", "b", "d", "c"]);;
}

test "bfs_cycle_once_each" {
    adj: dict[str, list[str]] = {
        "a": ["b"],
        "b": ["a"]
    };
    got = bfs(adj, "a");
    assert (got == ["a", "b"]);;
}

test "unknown_start_empty" {
    adj: dict[str, list[str]] = {
        "a": ["b"],
        "b": []
    };
    got_bfs = bfs(adj, "z");
    got_dfs_i = dfs_iterative(adj, "z");
    got_dfs_r = dfs_recursive(adj, "z");
    assert (got_bfs == []);;
    assert (got_dfs_i == []);;
    assert (got_dfs_r == []);;
}

test "bfs_diamond_adversarial" {
    adj: dict[str, list[str]] = {
        "r": ["a", "b"],
        "a": ["m"],
        "b": ["m"],
        "m": ["r"]
    };
    got = bfs(adj, "r");
    assert (got == ["r", "a", "b", "m"]);;
}
