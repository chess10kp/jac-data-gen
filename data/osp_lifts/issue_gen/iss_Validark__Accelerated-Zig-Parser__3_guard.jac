# iss_Validark__Accelerated-Zig-Parser__3.jac
# Lift: iterative AST adjacency traversal (DFS/BFS) per Validark/Accelerated-Zig-Parser#3

node Ast {
    has nid: str;
    has label: str;
}

edge Child {}

node Graph {
    has by_id: dict[str, Ast] = {};
}

walker DfsLabels {
    has claimed: dict[str, bool] = {};
    has labels: list[str] = [];
    has target: str = "";

    can begin with Graph entry {
        if self.target in here.by_id {
            visit [here.by_id[self.target]];
        } else {
            print("dfs:unknown");
            disengage;
        }
    }

    can step with Ast entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.labels.append(here.label);
        print(here.label);
        kids: list[Ast] = [];
        for ch in [here ->:Child:->][?:Ast] {
            kids.append(ch);
        }
        i = len(kids) - 1;
        while i >= 0 {
            visit :0: [kids[i]];
            i -= 1;
        }
    }
}

walker BfsLabels {
    has claimed: dict[str, bool] = {};
    has labels: list[str] = [];
    has target: str = "";

    can begin with Graph entry {
        if self.target in here.by_id {
            visit [here.by_id[self.target]];
        } else {
            print("bfs:unknown");
            disengage;
        }
    }

    can step with Ast entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.labels.append(here.label);
        print(here.label);
        for ch in [here ->:Child:->][?:Ast] {
            visit [ch];
        }
    }
}

def make_node(nid: str, label: str) -> Ast {
    return Ast(nid=nid, label=label);
}

def wire_child(parent: Ast, child: Ast) -> None {
    parent +>:Child:+> child;
}

def new_graph() -> Graph {
    g = Graph(by_id={});
    root ++> g;
    return g;
}

def index_node(graph: Graph, nd: Ast) -> None {
    graph.by_id[nd.nid] = nd;
    graph ++> nd;
}

def dfs_labels(graph: Graph, root_nid: str) -> list[str] {
    w = graph spawn DfsLabels(target=root_nid);
    return w.labels;
}

def bfs_labels(graph: Graph, root_nid: str) -> list[str] {
    w = graph spawn BfsLabels(target=root_nid);
    return w.labels;
}

test "dfs_chain_preorder" {
    g = new_graph();
    r = make_node("r", "Root");
    a = make_node("a", "Assign");
    b = make_node("b", "BinOp");
    index_node(g, r);
    index_node(g, a);
    index_node(g, b);
    wire_child(r, a);
    wire_child(a, b);
    got = dfs_labels(g, "r");
    assert got == ["Root", "Assign", "BinOp"];
}

test "bfs_level_order" {
    g = new_graph();
    r = make_node("r", "Root");
    l = make_node("l", "Left");
    rt = make_node("t", "Right");
    index_node(g, r);
    index_node(g, l);
    index_node(g, rt);
    wire_child(r, l);
    wire_child(r, rt);
    got = bfs_labels(g, "r");
    assert got == ["Root", "Left", "Right"];
}

test "diamond_adversarial_revisit_skip" {
    g = new_graph();
    r = make_node("r", "R");
    a = make_node("a", "A");
    b = make_node("b", "B");
    c = make_node("c", "C");
    index_node(g, r);
    index_node(g, a);
    index_node(g, b);
    index_node(g, c);
    wire_child(r, a);
    wire_child(r, b);
    wire_child(b, c);
    wire_child(a, c);
    got = dfs_labels(g, "r");
    assert got == ["R", "A", "C", "B"];
}

test "unknown_root_returns_empty" {
    g = new_graph();
    n = make_node("x", "X");
    index_node(g, n);
    assert dfs_labels(g, "missing") == [];
    assert bfs_labels(g, "nope") == [];
}

test "cycle_claim_map_no_repeat" {
    g = new_graph();
    a = make_node("a", "A");
    b = make_node("b", "B");
    index_node(g, a);
    index_node(g, b);
    wire_child(a, b);
    wire_child(b, a);
    got = dfs_labels(g, "a");
    assert got == ["A", "B"];
}
