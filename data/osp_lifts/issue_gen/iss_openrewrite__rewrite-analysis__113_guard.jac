node DataNode {
    has cid: str;
    has label: str;
}
edge ArgToSelect {}
edge SelectToArg {}
node FlowGraph {
    has store: dict[str, DataNode] = {};
}
walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];
    can step with DataNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.result.append(here.cid);
        print(here.cid);
        nxt: list[DataNode] = [];
        for ch in [here ->:ArgToSelect:->][?:DataNode] {
            nxt.append(ch);
        }
        for ch in [here ->:SelectToArg:->][?:DataNode] {
            nxt.append(ch);
        }
        visit :0: nxt else { disengage; }
    }
}
def new_graph() -> FlowGraph {
    g: FlowGraph = FlowGraph();
    return g;
}
def add_node(g: FlowGraph, cid: str) -> bool {
    if cid in g.store { return False; }
    nd: DataNode = DataNode(cid=cid, label=cid);
    g.store[cid] = nd;
    return True;
}
def add_arg_to_select(g: FlowGraph, src: str, dst: str) -> bool {
    if src in g.store {
        if dst in g.store {
            s: DataNode = g.store[src] as DataNode;
            d: DataNode = g.store[dst] as DataNode;
            s +>:ArgToSelect:+> d;
            return True;
        }
    }
    return False;
}
def add_select_to_arg(g: FlowGraph, src: str, dst: str) -> bool {
    if src in g.store {
        if dst in g.store {
            s: DataNode = g.store[src] as DataNode;
            d: DataNode = g.store[dst] as DataNode;
            s +>:SelectToArg:+> d;
            return True;
        }
    }
    return False;
}
def compute_variable_assignment(g: FlowGraph, start: str) -> list[str] {
    if start in g.store {
        st: DataNode = g.store[start] as DataNode;
        init_claimed: dict[str, bool] = {};
        init_result: list[str] = [];
        w: ClosureWalker = st spawn ClosureWalker(claimed=init_claimed, result=init_result);
        res: list[str] = w.result;
        return sorted(res);
    }
    return [];
}
def get_nodes(g: FlowGraph) -> list[str] {
    out: list[str] = [];
    for k in g.store {
        out.append(k);
    }
    return sorted(out);
}
with entry {
    g: FlowGraph = new_graph();
    root ++> g;
    add_node(g, "a");
    add_node(g, "b");
    add_arg_to_select(g, "a", "b");
    add_select_to_arg(g, "b", "a");
    res: list[str] = compute_variable_assignment(g, "a");
    print(res);
    root spawn ClosureWalker(claimed={}, result=[]);
}

test "diamond_adversarial_revisit_bounded" {
    g: FlowGraph = new_graph();
    add_node(g, "a"); add_node(g, "b"); add_node(g, "c"); add_node(g, "d");
    add_arg_to_select(g, "d", "a");
    add_arg_to_select(g, "a", "b");
    add_select_to_arg(g, "a", "c");
    add_arg_to_select(g, "b", "d");
    add_select_to_arg(g, "c", "d");
    res: list[str] = compute_variable_assignment(g, "a");
    assert(res == ["a", "b", "c", "d"]);
}
test "unknown_id_tolerance" {
    g: FlowGraph = new_graph();
    add_node(g, "a");
    res: list[str] = compute_variable_assignment(g, "missing");
    assert(len(res) == 0);
    ok: bool = add_arg_to_select(g, "a", "missing");
    assert(ok == False);
    ok2: bool = add_select_to_arg(g, "missing", "a");
    assert(ok2 == False);
    ok3: bool = add_node(g, "a");
    assert(ok3 == False);
}
test "mutual_arg_select_cycle_bounded" {
    g: FlowGraph = new_graph();
    add_node(g, "arg");
    add_node(g, "sel");
    add_arg_to_select(g, "arg", "sel");
    add_select_to_arg(g, "sel", "arg");
    add_arg_to_select(g, "sel", "arg");
    add_select_to_arg(g, "arg", "sel");
    res: list[str] = compute_variable_assignment(g, "arg");
    assert(res == ["arg", "sel"]);
    res2: list[str] = compute_variable_assignment(g, "sel");
    assert(res2 == ["arg", "sel"]);
}
test "self_loop_not_infinite" {
    g: FlowGraph = new_graph();
    add_node(g, "x");
    add_arg_to_select(g, "x", "x");
    add_select_to_arg(g, "x", "x");
    res: list[str] = compute_variable_assignment(g, "x");
    assert(res == ["x"]);
}
test "isolated_and_disconnected" {
    g: FlowGraph = new_graph();
    add_node(g, "a");
    add_node(g, "b");
    add_node(g, "c");
    res: list[str] = compute_variable_assignment(g, "a");
    assert(res == ["a"]);
    res2: list[str] = get_nodes(g);
    assert(res2 == ["a", "b", "c"]);
}
