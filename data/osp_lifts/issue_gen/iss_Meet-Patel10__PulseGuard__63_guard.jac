"""Meet-Patel10/PulseGuard#63 - Topological sort and cycle detection for service dependencies."""

node Service {
    has sid: str;
}

edge Depends {}

walker CycleWalker {
    has claimed: dict[str, bool] = {};
    has on_stack: dict[str, bool] = {};
    has found_cycle: bool = False;

    can probe with Service entry {
        if self.found_cycle {
            disengage;
        }
        if here.sid == "__root__" {
            print("cycle probe root");
            kids: list[Service] = [];
            for ch in [here ->:->][?:Service] {
                kids.append(ch);
            }
            kids = _sorted_services(kids);
            if kids {
                visit :0: kids;
            } else {
                disengage;
            }
        } elif here.sid in self.on_stack {
            self.found_cycle = True;
            print("cycle hit", here.sid);
            disengage;
        } elif here.sid in self.claimed {
            skip;
        } else {
            self.on_stack[here.sid] = True;
            kids: list[Service] = [];
            for ch in [here ->:Depends:->][?:Service] {
                kids.append(ch);
            }
            kids = _sorted_services(kids);
            if kids {
                visit :0: kids;
            }
            self.on_stack[here.sid] = False;
            self.claimed[here.sid] = True;
            print("cycle visited", here.sid);
        }
    }
}

walker TopoWalker {
    has claimed: dict[str, bool] = {};
    has on_stack: dict[str, bool] = {};
    has order: list[str] = [];

    can walk with Service entry {
        if here.sid == "__root__" {
            print("topo root");
            kids: list[Service] = [];
            for ch in [here ->:->][?:Service] {
                kids.append(ch);
            }
            kids = _sorted_services(kids);
            if kids {
                visit :0: kids;
            } else {
                disengage;
            }
        } elif here.sid in self.on_stack {
            print("topo cycle", here.sid);
            disengage;
        } elif here.sid in self.claimed {
            skip;
        } else {
            self.on_stack[here.sid] = True;
            kids: list[Service] = [];
            for ch in [here ->:Depends:->][?:Service] {
                kids.append(ch);
            }
            kids = _sorted_services(kids);
            if kids {
                visit :0: kids;
            }
            self.on_stack[here.sid] = False;
            self.claimed[here.sid] = True;
            self.order.append(here.sid);
            print("topo add", here.sid);
        }
    }
}

def _sorted_services(nodes: list[Service]) -> list[Service] {
    out: list[Service] = [];
    sids: list[str] = [];
    for nd in nodes {
        sids.append(nd.sid);
    }
    sids = sorted(sids);
    for sid in sids {
        for nd in nodes {
            if nd.sid == sid {
                out.append(nd);
            }
        }
    }
    return out;
}

def build_service_graph(services: list[str], dependencies: list[tuple[str, str]]) -> Service {
    graph_root = Service(sid="__root__");
    lookup: dict[str, Service] = {};
    for name in services {
        if name not in lookup {
            nd = Service(sid=name);
            graph_root ++> nd;
            lookup[name] = nd;
        }
    }
    for edge in dependencies {
        frm = edge[0];
        to = edge[1];
        if frm in lookup {
            if to in lookup {
                lookup[frm] +>:Depends:+> lookup[to];
            }
        }
    }
    return graph_root;
}

def has_circular_dependency(services: list[str], dependencies: list[tuple[str, str]]) -> bool {
    graph_root = build_service_graph(services, dependencies);
    w = graph_root spawn CycleWalker(claimed={}, on_stack={}, found_cycle=False);
    return w.found_cycle;
}

def topological_order(services: list[str], dependencies: list[tuple[str, str]]) -> list[str] {
    graph_root = build_service_graph(services, dependencies);
    cw = graph_root spawn CycleWalker(claimed={}, on_stack={}, found_cycle=False);
    if cw.found_cycle {
        raise ValueError("circular dependency detected");
    }
    tw = graph_root spawn TopoWalker(claimed={}, on_stack={}, order=[]);
    rev: list[str] = tw.order;
    out: list[str] = [];
    i = len(rev) - 1;
    while i >= 0 {
        out.append(rev[i]);
        i = i - 1;
    }
    return out;
}

test "empty_no_cycle" {
    assert (not has_circular_dependency([], []));
    order = topological_order([], []);
    assert (order == []);
}

test "linear_topo" {
    order = topological_order(["a", "b", "c"], [("a", "b"), ("b", "c")]);
    assert (order == ["a", "b", "c"]);
}

test "cycle_detected" {
    assert (has_circular_dependency(["a", "b"], [("a", "b"), ("b", "a")]));
}

test "cycle_topo_raises" {
    failed = False;
    try {
        topological_order(["a", "b"], [("a", "b"), ("b", "a")]);
    } except ValueError {
        failed = True;
    }
    assert (failed);
}

test "single_service" {
    assert (not has_circular_dependency(["x"], []));
    assert (topological_order(["x"], []) == ["x"]);
}

test "diamond_dag" {
    deps = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")];
    order = topological_order(["a", "b", "c", "d"], deps);
    assert (order[0] == "a");
    assert (order[3] == "d");
    assert (order.index("b") < order.index("d"));
    assert (order.index("c") < order.index("d"));
}
