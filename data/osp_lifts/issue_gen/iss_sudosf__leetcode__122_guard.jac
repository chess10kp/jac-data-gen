"""OSP lift for sudosf/leetcode#122 — BFS/DFS without hand-rolled queues."""

node Vertex {
    has label: str;
}

edge Arc {}

walker BfsWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has start: str = "";

    can begin with Root entry {
        for v in [-->][?:Vertex] {
            if v.label == self.start {
                visit [v];
            }
        }
    }

    can step with Vertex entry {
        if here.label in self.claimed {
            skip;
        }
        self.claimed[here.label] = True;
        self.order.append(here.label);
        visit [-->];
    }

    can finish with Root exit {
        report self.order;
    }
}

walker DfsWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has start: str = "";

    can begin with Root entry {
        for v in [-->][?:Vertex] {
            if v.label == self.start {
                visit :0: [v];
            }
        }
    }

    can step with Vertex entry {
        if here.label in self.claimed {
            skip;
        }
        self.claimed[here.label] = True;
        self.order.append(here.label);
        visit :0: [-->];
    }

    can finish with Root exit {
        report self.order;
    }
}

def _wire(edges: list[tuple[str, str]]) -> None {
    nodes: dict[str, Vertex] = {};
    for (a, b) in edges {
        if a not in nodes {
            na = Vertex(label=a);
            root ++> na;
            nodes[a] = na;
        }
        if b not in nodes {
            nb = Vertex(label=b);
            root ++> nb;
            nodes[b] = nb;
        }
        nodes[a] +>:Arc:+> nodes[b];
    }
}

def bfs_order(edges: list[tuple[str, str]], start: str) -> list[str] {
    _wire(edges);
    w = root spawn BfsWalker(start=start);
    return w.reports[0] if w.reports else [];
}

def dfs_preorder(edges: list[tuple[str, str]], start: str) -> list[str] {
    _wire(edges);
    w = root spawn DfsWalker(start=start);
    return w.reports[0] if w.reports else [];
}

def reachable(edges: list[tuple[str, str]], start: str) -> list[str] {
    got = bfs_order(edges, start);
    return sorted(set(got));
}

test "diamond adversarial bfs order" {
    edges = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")];
    assert bfs_order(edges, "a") == ["a", "b", "c", "d"];
}

test "cycle once per node" {
    edges = [("a", "b"), ("b", "c"), ("c", "a")];
    got = bfs_order(edges, "a");
    assert sorted(got) == ["a", "b", "c"];
    assert len(got) == 3;
}

test "dfs covers diamond" {
    edges = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")];
    got = dfs_preorder(edges, "a");
    assert got[0] == "a";
    assert sorted(got) == ["a", "b", "c", "d"];
}

test "unknown start empty" {
    assert bfs_order([], "missing") == [];
}
