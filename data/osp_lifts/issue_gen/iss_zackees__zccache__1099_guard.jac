"""OSP lift: workflow DAG ordering. Source: zackees/zccache#1099."""

node Step {
    has name: str;
}

edge Next {}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for s in [-->][?:Step] {
            if s.name == self.start {
                visit [s];
            }
        }
    }

    can step with Step entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Next:->];
    }

    can finish with Root exit {
        report self.reached;
    }
}

walker TopoWalker {
    has order: list[str] = [];
    has indeg: dict[str, int] = {};
    has ready: list[str] = [];
    has adj: dict[str, list[str]] = {};

    can begin with Root entry {
        for s in [-->][?:Step] {
            if s.name not in self.indeg {
                self.indeg[s.name] = 0;
            }
        }
        for (src, dst) in self.adj.items() {
            for nxt in dst {
                self.indeg[nxt] = self.indeg.get(nxt, 0) + 1;
            }
        }
        self.ready = sorted([n for (n, d) in self.indeg.items() if d == 0]);
        while self.ready {
            node = self.ready.pop(0);
            self.order.append(node);
            for nxt in sorted(self.adj.get(node, [])) {
                self.indeg[nxt] -= 1;
                if self.indeg[nxt] == 0 {
                    self.ready.append(nxt);
                    self.ready = sorted(self.ready);
                }
            }
        }
        report self.order;
    }
}

def _wire(edges: list[tuple[str, str]]) -> tuple[dict[str, Step], dict[str, list[str]]] {
    nodes: dict[str, Step] = {};
    adj: dict[str, list[str]] = {};
    for (a, b) in edges {
        if a not in nodes {
            nodes[a] = Step(name=a);
            root ++> nodes[a];
        }
        if b not in nodes {
            nodes[b] = Step(name=b);
            root ++> nodes[b];
        }
        nodes[a] +>:Next:+> nodes[b];
        adj.setdefault(a, []).append(b);
        adj.setdefault(b, []);
    }
    return (nodes, adj);
}

def build_order(edges: list[tuple[str, str]]) -> list[str] {
    (_, adj) = _wire(edges);
    if not adj {
        return [];
    }
    w = root spawn TopoWalker(indeg={}, ready=[], adj=adj, order=[]);
    got = w.reports[0] if w.reports else [];
    if len(got) != len(adj) {
        return [];
    }
    return got;
}

def workflow_reachable(start: str, edges: list[tuple[str, str]]) -> list[str] {
    (nodes, _) = _wire(edges);
    if start not in nodes {
        return [];
    }
    w = root spawn ReachWalker(start=start, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

test "diamond reach once per step" {
    edges = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")];
    got = workflow_reachable("a", edges);
    assert got == ["a", "b", "c", "d"];
}

test "cycle topo empty" {
    edges = [("a", "b"), ("b", "c"), ("c", "a")];
    assert build_order(edges) == [];
}

test "dag order deterministic" {
    edges = [("compile", "link"), ("link", "test"), ("compile", "lint")];
    assert build_order(edges) == ["compile", "link", "lint", "test"];
}
