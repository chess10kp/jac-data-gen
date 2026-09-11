"""ditto-assistant/ditto-subnet#503 — Recursive compositional query dependency graph."""

node QueryStep {
    has name: str;
}

edge DependsOn {}

obj QueryGraph {
    has steps: dict[str, QueryStep] = {};
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with QueryStep entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:DependsOn:->][?:QueryStep];
    }
}

def load_query_graph(
    steps: list[str],
    depends_edges: list[tuple[str, str]],
) -> QueryGraph {
    g = QueryGraph();
    for s in steps {
        nd = QueryStep(name=s);
        root ++> nd;
        g.steps[s] = nd;
    }
    for (upstream, downstream) in depends_edges {
        u = g.steps.get(upstream, None);
        d = g.steps.get(downstream, None);
        if u is not None and d is not None { d +>:DependsOn:+> u; }
    }
    return g;
}

def evaluation_order(store: QueryGraph, `root: str) -> list[str] {
    nd = store.steps.get(`root, None);
    if nd is None { return []; }
    root_id = `root;
    depth: dict[str, int] = {root_id: 0};
    order: list[tuple[int, str]] = [(0, root_id)];
    frontier: list[QueryStep] = [nd];
    seen: dict[str, bool] = {root_id: True};
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        cur_depth = depth[cur.name];
        for dep in [cur ->:DependsOn:->][?:QueryStep] {
            nd2 = cur_depth + 1;
            if not (dep.name in seen) {
                seen[dep.name] = True;
                depth[dep.name] = nd2;
                order.append((nd2, dep.name));
                frontier.append(dep);
            } elif nd2 > depth.get(dep.name, 0) {
                depth[dep.name] = nd2;
                order.append((nd2, dep.name));
            }
        }
    }
    for i in range(len(order)) {
        for j in range(i + 1, len(order)) {
            if order[i][0] > order[j][0] or (
                order[i][0] == order[j][0] and order[i][1] > order[j][1]
            ) {
                tmp = order[i];
                order[i] = order[j];
                order[j] = tmp;
            }
        }
    }
    out: list[str] = [];
    for pair in order { out.append(pair[1]); }
    return out;
}

def reachable_steps(store: QueryGraph, `root: str) -> list[str] {
    nd = store.steps.get(`root, None);
    if nd is None { return []; }
    w = nd spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

test "query dependency reach" {
    g = load_query_graph(
        ["answer", "aggregate", "join_ab", "filter_a", "source_a", "source_b"],
        [
            ("source_a", "filter_a"),
            ("filter_a", "join_ab"),
            ("source_b", "join_ab"),
            ("join_ab", "aggregate"),
            ("aggregate", "answer"),
        ],
    );
    assert reachable_steps(g, "answer") == [
        "aggregate", "answer", "filter_a", "join_ab", "source_a", "source_b"
    ];
    order = evaluation_order(g, "answer");
    assert order[0] == "answer";
    assert len(order) == 6;
}

test "diamond adversarial revisit" {
    g2 = load_query_graph(
        ["out", "mid_l", "mid_r", "base"],
        [("base", "mid_l"), ("base", "mid_r"), ("mid_l", "out"), ("mid_r", "out")],
    );
    assert reachable_steps(g2, "out") == ["base", "mid_l", "mid_r", "out"];
}
