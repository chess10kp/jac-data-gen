"""Guard: rizinorg/rizin#6181."""

node GraphNode { has nid: str; }
edge OutLink {}

obj RzGraph { has nodes: dict[str, GraphNode] = {}; }

walker BfsReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has frontier: list[GraphNode] = [];

    can step with GraphNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        for nxt in [here ->:OutLink:->][?:GraphNode] {
            if not (nxt.nid in self.claimed) {
                self.frontier.append(nxt);
            }
        }
        if len(self.frontier) > 0 {
            nxt = self.frontier.pop(0);
            visit [nxt];
        } else {
            disengage;
        }
    }
}

def load_graph(
    node_ids: list[str],
    edges: list[tuple[str, str]],
) -> RzGraph {
    g = RzGraph();
    for nid in node_ids {
        if nid not in g.nodes {
            nd = GraphNode(nid=nid);
            root ++> nd;
            g.nodes[nid] = nd;
        }
    }
    for (src, dst) in edges {
        a = g.nodes.get(src, None);
        b = g.nodes.get(dst, None);
        if a is not None and b is not None { a +>:OutLink:+> b; }
    }
    return g;
}

def reachable_from(g: RzGraph, start: str) -> list[str] {
    nd = g.nodes.get(start, None);
    if nd is None { return []; }
    w = nd spawn BfsReach(claimed={}, reached=[], frontier=[]);
    return sorted(w.reached);
}

def has_path(g: RzGraph, src: str, dst: str) -> bool {
    reached = reachable_from(g, src);
    for nid in reached {
        if nid == dst { return True; }
    }
    return False;
}

test "call graph reachability" {
    g = load_graph(
        ["main", "parse", "analyze", "emit", "optimize"],
        [
            ("main", "parse"),
            ("parse", "analyze"),
            ("analyze", "emit"),
            ("analyze", "optimize"),
            ("optimize", "emit"),
        ],
    );
    assert reachable_from(g, "main") == ["analyze", "emit", "main", "optimize", "parse"];
    assert has_path(g, "main", "emit") is True;
    assert has_path(g, "emit", "main") is False;
}

test "diamond adversarial bfs" {
    g = load_graph(
        ["root", "left", "right", "join"],
        [("root", "left"), ("root", "right"), ("left", "join"), ("right", "join")],
    );
    assert reachable_from(g, "root") == ["join", "left", "right", "root"];
}

test "unknown start tolerant" {
    g = load_graph(["solo"], []);
    assert reachable_from(g, "missing") == [];
}
