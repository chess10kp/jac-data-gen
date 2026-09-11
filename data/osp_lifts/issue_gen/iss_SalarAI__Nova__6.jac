"""SalarAI/Nova#6 — Implement Graph and BFS/DFS."""

class GraphError(ValueError) {}

obj Graph { has stamp: int = 0; }
node GNode { has nid: str; has label: str = ""; }
edge GEdge {}

def _find(nid: str) -> GNode | None {
    for n in [-->][?:GNode] { if n.nid == nid { return n; } }
    return None;
}

def add_node(g: Graph, node_id: str, label: str = "") -> None {
    _ = g;
    if _find(node_id) is not None { return; }
    root ++> GNode(nid=node_id, label=label);
}

def add_edge(g: Graph, src: str, dst: str) -> None {
    _ = g;
    a = _find(src); b = _find(dst);
    if a is None or b is None { raise GraphError("unknown node"); }
    a +>:GEdge:+> b;
}

walker BfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can step with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        visit [->:GEdge:->] else { disengage; };
    }
}

walker DfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can step with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        visit :0: [->:GEdge:->] else { disengage; };
    }
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    can step with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        visit [->:GEdge:->] else { disengage; };
    }
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has stack: list[str] = [];
    has found: bool = False;
    can step with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.stack.append(here.nid);
        for nxt in [here ->:GEdge:->][?:GNode] {
            if nxt.nid in self.stack { self.found = True; }
        }
        visit [->:GEdge:->] else { disengage; };
    }
}

def bfs_order(g: Graph, start: str) -> list[str] {
    _ = g;
    anchor = _find(start);
    if anchor is None { return []; }
    w = anchor spawn BfsWalk(claimed={}, order=[]);
    return sorted(w.order);
}

def dfs_order(g: Graph, start: str) -> list[str] {
    _ = g;
    anchor = _find(start);
    if anchor is None { return []; }
    w = anchor spawn DfsWalk(claimed={}, order=[]);
    return sorted(w.order);
}

def is_reachable(g: Graph, start: str, target: str) -> bool {
    _ = g;
    anchor = _find(start);
    if anchor is None { return False; }
    w = anchor spawn ReachWalk(claimed={}, reached=[]);
    return target in w.reached;
}

def has_cycle(g: Graph) -> bool {
    _ = g;
    for n in [-->][?:GNode] {
        w = n spawn CycleProbe(claimed={}, stack=[], found=False);
        if w.found { return True; }
    }
    return False;
}
