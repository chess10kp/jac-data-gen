"""Guard: aetorresdev/ai-minions#341."""

obj ExecGraph { has nodes: dict[str, Task] = {}; }
node Task { has tid: str; }
edge DependsOn {}

def load_exec_graph(
    nodes: list[str],
    edges: list[tuple[str, str]],
) -> ExecGraph {
    g = ExecGraph();
    for n in nodes {
        if n not in g.nodes {
            nd = Task(tid=n);
            root ++> nd;
            g.nodes[n] = nd;
        }
    }
    for (src, dst) in edges {
        a = g.nodes.get(src, None);
        b = g.nodes.get(dst, None);
        if a is not None and b is not None { a +>:DependsOn:+> b; }
    }
    return g;
}

def detect_exec_cycles(g: ExecGraph) -> list[str] {
    gray: dict[str, bool] = {};
    black: dict[str, bool] = {};
    cycles: list[str] = [];

    def dfs(nid: str) -> None {
        if nid in black { return; }
        if nid in gray {
            cycles.append("cycle: " + nid);
            return;
        }
        gray[nid] = True;
        nd = g.nodes.get(nid, None);
        if nd is not None {
            for nxt in [nd ->:DependsOn:->][?:Task] {
                dfs(nxt.tid);
            }
        }
        del gray[nid];
        black[nid] = True;
    }

    for nid in sorted(g.nodes.keys()) {
        if nid not in black { dfs(nid); }
    }
    return cycles;
}

def valid_exec_graph(g: ExecGraph) -> bool {
    return len(detect_exec_cycles(g)) == 0;
}

test "controlled cycle rejected" {
    g = load_exec_graph(["a", "b"], [("a", "b"), ("b", "a")]);
    assert not valid_exec_graph(g);
    assert len(detect_exec_cycles(g)) >= 1;
}

test "acyclic graph accepted" {
    g = load_exec_graph(["a", "b", "c"], [("a", "b"), ("b", "c")]);
    assert valid_exec_graph(g);
}

test "diamond acyclic accepted" {
    g = load_exec_graph(
        ["entry", "left", "right", "join"],
        [("entry", "left"), ("entry", "right"), ("left", "join"), ("right", "join")],
    );
    assert valid_exec_graph(g);
}
