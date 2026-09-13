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
