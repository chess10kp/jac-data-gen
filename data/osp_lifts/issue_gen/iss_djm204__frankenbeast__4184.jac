# iss_djm204__frankenbeast__4184.jac
# djm204/frankenbeast#4184 — RecursivePlanner._buildSubGraph discards fromTasks topo.

node Task {
    has tid: str;
}

edge Dep {}

node TopoResult {
    has order: list[str] = [];
    has cyclic: bool = False;
}

walker TopoWalk {
    has claimed: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has order: list[str] = [];
    has cyclic: bool = False;

    can descend with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        if here.tid in self.stack {
            self.cyclic = True;
            print("cyclic_dependency", here.tid);
            disengage;
        }
        self.stack[here.tid] = True;
        deps: list[Task] = [];
        for d in [here ->:Dep:->][?:Task] {
            deps.append(d);
        }
        if deps {
            visit deps;
        }
        self.stack[here.tid] = False;
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        print("topo_visit", here.tid);
    }
}

walker DemoWalk {
    has claimed: dict[str, bool] = {};

    can show with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        print("demo_task", here.tid);
        kids: list[Task] = [];
        for ch in [here ->:Dep:->][?:Task] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        }
    }
}

def build_graph(spec: list[list[str]]) -> list[Task] {
    tid_map: dict[str, Task] = {};
    nodes: list[Task] = [];
    for row in spec {
        tid: str = row[0];
        nd = Task(tid=tid);
        tid_map[tid] = nd;
        root ++> nd;
        nodes.append(nd);
    }
    for row in spec {
        tid: str = row[0];
        src = tid_map[tid] as Task;
        idx: int = 1;
        while idx < len(row) {
            dep_id: str = row[idx];
            if dep_id in tid_map {
                dep_nd = tid_map[dep_id] as Task;
                src +>:Dep:+> dep_nd;
            }
            idx = idx + 1;
        }
    }
    return nodes;
}

def compute_topo(spec: list[list[str]]) -> TopoResult {
    nodes: list[Task] = build_graph(spec);
    res = TopoResult(order=[], cyclic=False);
    if not nodes {
        return res;
    }
    wk = nodes[0] spawn TopoWalk(claimed={}, stack={}, order=[], cyclic=False);
    si: int = 1;
    while si < len(nodes) {
        nxt = nodes[si];
        wk = nxt spawn TopoWalk(
            claimed=wk.claimed,
            stack={},
            order=wk.order,
            cyclic=wk.cyclic
        );
        si = si + 1;
    }
    res.order = wk.order;
    res.cyclic = wk.cyclic;
    return res;
}

def create_with_raw_edges(spec: list[list[str]]) -> list[str] {
    out: list[str] = [];
    for row in spec {
        out.append(row[0]);
    }
    return out;
}

def has_cycle(spec: list[list[str]]) -> bool {
    res = compute_topo(spec);
    return res.cyclic;
}

def from_tasks(spec: list[list[str]]) -> list[str] {
    res = compute_topo(spec);
    if res.cyclic {
        return [];
    }
    return res.order;
}

def build_sub_graph_buggy(spec: list[list[str]]) -> list[str] {
    _validated: list[str] = from_tasks(spec);
    return create_with_raw_edges(spec);
}

def build_sub_graph(spec: list[list[str]]) -> list[str] {
    return from_tasks(spec);
}

with entry {
    demo_spec: list[list[str]] = [["compile", "parse"], ["parse"], ["link", "compile"]];
    build_graph(demo_spec);
    root spawn DemoWalk(claimed={});
    demo_order: list[str] = build_sub_graph(demo_spec);
    print("build_sub_graph_demo", demo_order);
}
