"""Stellar-split/split-sdk#644 — iterative DFS cycle detection for payment deps."""

node PaymentNode {
    has nid: str;
}

edge Depends {}

walker CycleProbe {
    has nodes: dict[str, PaymentNode] = {};
    has finished: dict[str, bool] = {};
    has cycle: list[str] = [];
    has found: bool = False;

    can probe with PaymentNode entry {
        result = dfs_cycle_from(here, self.nodes, self.finished);
        if result {
            self.cycle = result;
            self.found = True;
            print("cycle", result);
        } else {
            print("acyclic_from", here.nid);
        }
        disengage;
    }
}

def build_payment_graph(graph: dict[str, list[str]]) -> dict[str, PaymentNode] {
    nodes: dict[str, PaymentNode] = {};
    keys: list[str] = [];
    for k in sorted(graph) {
        keys.append(k);
    }
    for nid in keys {
        nd = PaymentNode(nid=nid);
        nodes[nid] = nd;
    }
    for src in keys {
        deps: list[str] = graph[src];
        for dep in deps {
            if dep in nodes {
                src_nd = nodes[src] as PaymentNode;
                dep_nd = nodes[dep] as PaymentNode;
                src_nd +>:Depends:+> dep_nd;
            }
        }
    }
    return nodes;
}

def pop_stack(stack: list[str]) -> list[str] {
    out: list[str] = [];
    i: int = 0;
    while i < (len(stack) - 1) {
        out.append(stack[i]);
        i = i + 1;
    }
    return out;
}

def extract_cycle_path(stack: list[str], closing_id: str) -> list[str] {
    cycle: list[str] = [];
    started: bool = False;
    for nid in stack {
        if nid == closing_id {
            started = True;
        }
        if started {
            cycle.append(nid);
        }
    }
    cycle.append(closing_id);
    return cycle;
}

def dfs_cycle_from(
    start: PaymentNode,
    nodes: dict[str, PaymentNode],
    finished: dict[str, bool]
) -> list[str] | None {
    if start.nid in finished && finished[start.nid] {
        return None;
    }
    on_stack: dict[str, bool] = {};
    stack: list[str] = [];
    stack.append(start.nid);
    on_stack[start.nid] = True;
    while len(stack) > 0 {
        curr_id = stack[len(stack) - 1];
        curr = nodes[curr_id] as PaymentNode;
        advanced: bool = False;
        kids: list[PaymentNode] = [];
        for ch in [curr ->:Depends:->][?:PaymentNode] {
            kids.append(ch);
        }
        for kid in kids {
            kid_id = kid.nid;
            if kid_id in on_stack && on_stack[kid_id] {
                return extract_cycle_path(stack, kid_id);
            }
            if kid_id not in finished || not finished[kid_id] {
                if kid_id not in on_stack || not on_stack[kid_id] {
                    on_stack[kid_id] = True;
                    stack.append(kid_id);
                    advanced = True;
                    break;
                }
            }
        }
        if not advanced {
            stack = pop_stack(stack);
            finished[curr_id] = True;
            on_stack[curr_id] = False;
        }
    }
    return None;
}

def detect_cycle(graph: dict[str, list[str]]) -> list[str] | None {
    if len(graph) == 0 {
        return None;
    }
    nodes: dict[str, PaymentNode] = build_payment_graph(graph);
    finished: dict[str, bool] = {};
    ordered: list[str] = [];
    for k in sorted(graph) {
        ordered.append(k);
    }
    for start_id in ordered {
        if start_id in finished && finished[start_id] {
            continue;
        }
        start_nd = nodes[start_id] as PaymentNode;
        w = start_nd spawn CycleProbe(nodes=nodes, finished=finished);
        if w.found {
            return w.cycle;
        }
    }
    return None;
}

"""Stellar-split/split-sdk#644 — iterative DFS cycle detection for payment deps."""

node PaymentNode {
    has nid: str;
}

edge Depends {}

walker CycleProbe {
    has nodes: dict[str, PaymentNode] = {};
    has finished: dict[str, bool] = {};
    has cycle: list[str] = [];
    has found: bool = False;

    can probe with PaymentNode entry {
        result = dfs_cycle_from(here, self.nodes, self.finished);
        if result {
            self.cycle = result;
            self.found = True;
            print("cycle", result);
        } else {
            print("acyclic_from", here.nid);
        }
        disengage;
    }
}

def build_payment_graph(graph: dict[str, list[str]]) -> dict[str, PaymentNode] {
    nodes: dict[str, PaymentNode] = {};
    keys: list[str] = [];
    for k in sorted(graph) {
        keys.append(k);
    }
    for nid in keys {
        nd = PaymentNode(nid=nid);
        nodes[nid] = nd;
    }
    for src in keys {
        deps: list[str] = graph[src];
        for dep in deps {
            if dep in nodes {
                src_nd = nodes[src] as PaymentNode;
                dep_nd = nodes[dep] as PaymentNode;
                src_nd +>:Depends:+> dep_nd;
            }
        }
    }
    return nodes;
}

def pop_stack(stack: list[str]) -> list[str] {
    out: list[str] = [];
    i: int = 0;
    while i < (len(stack) - 1) {
        out.append(stack[i]);
        i = i + 1;
    }
    return out;
}

def extract_cycle_path(stack: list[str], closing_id: str) -> list[str] {
    cycle: list[str] = [];
    started: bool = False;
    for nid in stack {
        if nid == closing_id {
            started = True;
        }
        if started {
            cycle.append(nid);
        }
    }
    cycle.append(closing_id);
    return cycle;
}

def dfs_cycle_from(
    start: PaymentNode,
    nodes: dict[str, PaymentNode],
    finished: dict[str, bool]
) -> list[str] | None {
    if start.nid in finished && finished[start.nid] {
        return None;
    }
    on_stack: dict[str, bool] = {};
    stack: list[str] = [];
    stack.append(start.nid);
    on_stack[start.nid] = True;
    while len(stack) > 0 {
        curr_id = stack[len(stack) - 1];
        curr = nodes[curr_id] as PaymentNode;
        advanced: bool = False;
        kids: list[PaymentNode] = [];
        for ch in [curr ->:Depends:->][?:PaymentNode] {
            kids.append(ch);
        }
        for kid in kids {
            kid_id = kid.nid;
            if kid_id in on_stack && on_stack[kid_id] {
                return extract_cycle_path(stack, kid_id);
            }
            if kid_id not in finished || not finished[kid_id] {
                if kid_id not in on_stack || not on_stack[kid_id] {
                    on_stack[kid_id] = True;
                    stack.append(kid_id);
                    advanced = True;
                    break;
                }
            }
        }
        if not advanced {
            stack = pop_stack(stack);
            finished[curr_id] = True;
            on_stack[curr_id] = False;
        }
    }
    return None;
}

def detect_cycle(graph: dict[str, list[str]]) -> list[str] | None {
    if len(graph) == 0 {
        return None;
    }
    nodes: dict[str, PaymentNode] = build_payment_graph(graph);
    finished: dict[str, bool] = {};
    ordered: list[str] = [];
    for k in sorted(graph) {
        ordered.append(k);
    }
    for start_id in ordered {
        if start_id in finished && finished[start_id] {
            continue;
        }
        start_nd = nodes[start_id] as PaymentNode;
        w = start_nd spawn CycleProbe(nodes=nodes, finished=finished);
        if w.found {
            return w.cycle;
        }
    }
    return None;
}

test "empty_graph_no_cycle" {
    g: dict[str, list[str]] = {};
    r = detect_cycle(g);
    assert r == None;
}

test "acyclic_chain_no_cycle" {
    g: dict[str, list[str]] = {};
    g["a"] = ["b"];
    g["b"] = ["c"];
    g["c"] = [];
    r = detect_cycle(g);
    assert r == None;
}

test "simple_three_cycle" {
    g: dict[str, list[str]] = {};
    g["a"] = ["b"];
    g["b"] = ["c"];
    g["c"] = ["a"];
    r = detect_cycle(g);
    assert r == ["a", "b", "c", "a"];
}

test "self_loop_cycle" {
    g: dict[str, list[str]] = {};
    g["x"] = ["x"];
    r = detect_cycle(g);
    assert r == ["x", "x"];
}

test "isolated_component_cycle" {
    g: dict[str, list[str]] = {};
    g["p"] = [];
    g["m"] = ["n"];
    g["n"] = ["m"];
    r = detect_cycle(g);
    assert r == ["m", "n", "m"];
}

test "unknown_dep_ignored_acyclic" {
    g: dict[str, list[str]] = {};
    g["a"] = ["missing"];
    r = detect_cycle(g);
    assert r == None;
}
