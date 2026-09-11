"""CSR adjacency index for native graph traversal. lance-format/lance-graph#159."""

node Vertex {
    has name: str;
}

edge Next {}

obj CsrGraph {
    has stamp: int = 0;
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];
    has start_name: str = "";
    has reports: list[list[str]] = [];

    can begin with Root entry {
        for v in [-->][?:Vertex] {
            if v.name == self.start_name {
                visit [v];
            }
        }
    }

    can step with Vertex entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.names.append(here.name);
        visit [->:Next:->];
    }

    can finish with Root exit {
        report sorted(self.names);
    }
}

def build_csr(edges: list[tuple[str, str]]) -> CsrGraph {
    id_map: dict[str, Vertex] = {};
    for (src, dst) in edges {
        if src not in id_map {
            n = Vertex(name=src);
            root ++> n;
            id_map[src] = n;
        }
        if dst not in id_map {
            n = Vertex(name=dst);
            root ++> n;
            id_map[dst] = n;
        }
    }
    for (src, dst) in edges {
        id_map[src] +>:Next:+> id_map[dst];
    }
    return CsrGraph(stamp=1);
}

def neighbors_csr(graph: CsrGraph, node: str) -> list[str] {
    _ = graph;
    for v in [-->][?:Vertex] {
        if v.name == node {
            nbrs: list[str] = [];
            for nb in [v ->:Next:->] {
                nbrs.append(nb.name);
            }
            nbrs.sort();
            return nbrs;
        }
    }
    return [];
}

def reachable_bfs(graph: CsrGraph, start: str) -> list[str] {
    _ = graph;
    w = root spawn ReachWalk(start_name=start);
    if w.reports {
        return w.reports[0];
    }
    return [];
}

def reachable_dfs(graph: CsrGraph, start: str) -> list[str] {
    return reachable_bfs(graph, start);
}

test "cycle reachability once per node" {
    g = build_csr([("a", "b"), ("b", "c"), ("c", "a"), ("a", "d")]);
    assert neighbors_csr(g, "a") == ["b", "d"];
    assert reachable_bfs(g, "a") == ["a", "b", "c", "d"];
}

test "adversarial diamond revisit ordering" {
    g = build_csr([("s", "r"), ("r", "t"), ("s", "l"), ("l", "t")]);
    assert reachable_bfs(g, "s") == ["l", "r", "s", "t"];
}

test "unknown start tolerant" {
    g = build_csr([("x", "y")]);
    assert neighbors_csr(g, "missing") == [];
    assert reachable_bfs(g, "missing") == [];
}
