node GraphNode {
    has id: str;
}

edge Link {}

# build the sample graph from the issue, returns root node handle
def build_graph(adj: dict[str, list[str]]) -> GraphNode | None {
    nodes: dict[str, GraphNode] = {};
    ids: list[str] = sorted(adj.keys());
    for k in ids {
        nodes[k] = GraphNode(id=k);
    }
    created: set[tuple] = set();
    anchor: GraphNode | None = None;
    for k in ids {
        if anchor is None {
            anchor = nodes[k];
        }
        for nb in adj[k] {
            if nodes.get(nb) is None {
                continue;
            }
            pair: tuple = (k, nb);
            if pair not in created {
                nodes[k] +>:Link:+> nodes[nb];
                created.add(pair);
            }
        }
    }
    return anchor;
}

# public API: DFS traversal order as list of ids, matching issue's dfs()
def dfs(graph_root: GraphNode, start: str) -> list[str] {
    starts: list[GraphNode] = [graph_root];
    match: GraphNode | None = None;
    for s in starts {
        if s.id == start {
            match = s;
        }
    }
    if match is None {
        return [];
    }
    w = match spawn GraphWalker(order=[], claimed={});
    return w.order;
}

walker GraphWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with GraphNode entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        self.order.append(here.id);
        kids: list[GraphNode] = [];
        for e in [here ->:Link:->] {
            for t in [e ->] {
                kids.append(t);
            }
        }
        kids = sort_nodes(kids);
        if len(kids) == 0 {
            disengage;
        }
        visit kids;
    }
}

# deterministic neighbor ordering
def sort_nodes(ns: list[GraphNode]) -> list[GraphNode] {
    res: list[GraphNode] = [];
    keys: list[str] = [];
    lookup: dict[str, GraphNode] = {};
    for n in ns {
        keys.append(n.id);
        lookup[n.id] = n;
    }
    for k in sorted(keys) {
        res.append(lookup[k]);
    }
    return res;
}

with entry {
    adj = {
        "A": ["B", "C"],
        "B": ["A", "D", "E"],
        "C": ["A", "F"],
        "D": ["B"],
        "E": ["B", "F"],
        "F": ["C", "E"],
    };
    g = build_graph(adj);
    if g is not None {
        order = dfs(g, "A");
        print("Depth-First Search starting from vertex A:");
        print(" ".join(order));
    }
}

test "diamond_adversarial_revisit" {
    adj = {
        "S": ["L", "R"],
        "L": ["M", "S"],
        "R": ["M", "S"],
        "M": ["L", "R", "T"],
        "T": ["M"],
    };
    g = build_graph(adj);
    assert g is not None;
    if g is not None {
        order = dfs(g, "S");
        assert sorted(order) == ["L", "M", "R", "S", "T"];
        assert order[0] == "S";
        assert len(order) == 5;
    }
}

test "unknown_start_tolerance" {
    adj = {
        "A": ["B"],
        "B": ["A"],
    };
    g = build_graph(adj);
    assert g is not None;
    if g is not None {
        assert dfs(g, "ZZZ") == [];
        assert dfs(g, "A") == ["A", "B"];
    }
}

test "cycle_graph_full_closure" {
    adj = {
        "A": ["B"],
        "B": ["C"],
        "C": ["A"],
    };
    g = build_graph(adj);
    assert g is not None;
    if g is not None {
        order = dfs(g, "A");
        assert sorted(order) == ["A", "B", "C"];
    }
}

test "single_vertex_no_edges" {
    adj = {"X": []};
    g = build_graph(adj);
    assert g is not None;
    if g is not None {
        assert dfs(g, "X") == ["X"];
        assert dfs(g, "Y") == [];
    }
}

test "issue_fixture_canonical_order" {
    adj = {
        "A": ["B", "C"],
        "B": ["A", "D", "E"],
        "C": ["A", "F"],
        "D": ["B"],
        "E": ["B", "F"],
        "F": ["C", "E"],
    };
    g = build_graph(adj);
    assert g is not None;
    if g is not None {
        assert dfs(g, "A") == ["A", "B", "D", "E", "F", "C"];
    }
}

test "disconnected_component_excluded" {
    adj = {
        "A": ["B"],
        "B": ["A"],
        "Z": ["W"],
        "W": ["Z"],
    };
    g = build_graph(adj);
    assert g is not None;
    if g is not None {
        order = dfs(g, "A");
        assert sorted(order) == ["A", "B"];
    }
}
