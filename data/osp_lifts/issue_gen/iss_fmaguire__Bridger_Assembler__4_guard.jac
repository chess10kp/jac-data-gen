"""Reachability bipartite graph traversal — fmaguire/Bridger_Assembler#4."""

node BPNode {
    has cid: str;
    has part: int = -1;
}

edge Link {}

walker FindById {
    has target: str = "";
    has hit: BPNode | None = None;
    has claimed: dict[str, bool] = {};
    can seek with BPNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.hit = here;
            disengage;
        }
        for ch in [here ->:Link:->][?:BPNode] {
            if ch.cid not in self.claimed { visit [ch]; }
        }
        for ch in [here <-:Link:<-][?:BPNode] {
            if ch.cid not in self.claimed { visit [ch]; }
        }
    }
}

walker BfsOrder {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can step with BPNode entry {
        if here.cid == "__root__" { skip; }
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        for ch in [here ->:Link:->][?:BPNode] {
            if ch.cid != "__root__" and ch.cid not in self.claimed {
                visit [ch];
            }
        }
    }
}

walker DfsOrder {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can step with BPNode entry {
        if here.cid == "__root__" { skip; }
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        for ch in [here ->:Link:->][?:BPNode] {
            if ch.cid != "__root__" and ch.cid not in self.claimed {
                visit :0: [ch];
            }
        }
    }
}

walker BipartiteCheck {
    has claimed: dict[str, bool] = {};
    has color: dict[str, int] = {};
    has ok: bool = True;
    can paint with BPNode entry {
        if here.cid == "__root__" {
            for ch in [here ->:Link:->][?:BPNode] {
                if ch.cid != "__root__" { visit [ch]; }
            }
            disengage;
        }
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid not in self.color { self.color[here.cid] = 0; }
        my_c = self.color[here.cid];
        for ch in [here ->:Link:->][?:BPNode] {
            if ch.cid == "__root__" { continue; }
            if ch.cid in self.color {
                if self.color[ch.cid] == my_c { self.ok = False; }
            } else {
                self.color[ch.cid] = 1 - my_c;
            }
            if ch.cid not in self.claimed { visit [ch]; }
        }
        print(here.cid, self.ok);
    }
}

def find_node(graph_root: BPNode, node_id: str) -> BPNode | None {
    w = graph_root spawn FindById(target=node_id, claimed={});
    return w.hit;
}

def make_bp_graph(node_ids: list[str], edges: list[list[str]]) -> BPNode {
    id_map: dict[str, BPNode] = {};
    graph_root = BPNode(cid="__root__");
    root ++> graph_root;
    for nid in node_ids {
        nd = BPNode(cid=nid);
        id_map[nid] = nd;
        graph_root ++> nd;
    }
    for e in edges {
        a = id_map[e[0]] as BPNode;
        b = id_map[e[1]] as BPNode;
        a +>:Link:+> b;
        b +>:Link:+> a;
    }
    return graph_root;
}

def bfs_reach_order(graph_root: BPNode, start_id: str) -> list[str] {
    st = find_node(graph_root, start_id);
    if st is None { return []; }
    w = st spawn BfsOrder(claimed={});
    print(w.order);
    return w.order;
}

def dfs_reach_order(graph_root: BPNode, start_id: str) -> list[str] {
    st = find_node(graph_root, start_id);
    if st is None { return []; }
    w = st spawn DfsOrder(claimed={});
    print(w.order);
    return w.order;
}

def reachable_ids(graph_root: BPNode, start_id: str) -> list[str] {
    ord = bfs_reach_order(graph_root, start_id);
    seen: dict[str, bool] = {};
    ids: list[str] = [];
    for x in ord {
        if x not in seen {
            seen[x] = True;
            ids.append(x);
        }
    }
    ids = sorted(ids);
    print(ids);
    return ids;
}

def is_bipartite(graph_root: BPNode) -> bool {
    w = graph_root spawn BipartiteCheck(claimed={}, color={}, ok=True);
    print(w.ok);
    return w.ok;
}

test "diamond_adversarial_revisit" {
    g = make_bp_graph(
        ["a", "b", "c", "d"],
        [["a", "b"], ["a", "d"], ["b", "d"], ["a", "c"], ["c", "d"]]
    );
    assert bfs_reach_order(g, "a") == ["a", "b", "d", "c"];
}

test "bipartite_triangle_fail" {
    g = make_bp_graph(["a", "b", "c"], [["a", "b"], ["b", "c"], ["c", "a"]]);
    assert is_bipartite(g) == False;
}

test "isolated_start_only" {
    g = make_bp_graph(["solo"], []);
    assert bfs_reach_order(g, "solo") == ["solo"];
}

test "reachable_ids_sorted" {
    g = make_bp_graph(
        ["a", "b", "c", "d"],
        [["a", "b"], ["a", "d"], ["b", "d"], ["a", "c"], ["c", "d"]]
    );
    assert reachable_ids(g, "a") == ["a", "b", "c", "d"];
}

test "bipartite_square_ok" {
    g = make_bp_graph(["a", "b", "c", "d"], [["a", "b"], ["b", "c"], ["c", "d"], ["d", "a"]]);
    assert is_bipartite(g) == True;
}

test "dfs_insertion_order" {
    g = make_bp_graph(
        ["a", "b", "c", "d"],
        [["a", "b"], ["a", "d"], ["b", "d"], ["a", "c"], ["c", "d"]]
    );
    assert dfs_reach_order(g, "a") == ["a", "c", "d", "b"];
}
