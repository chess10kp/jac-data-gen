"""djm204/frankenbeast#4561 — validated PlanGraph fromTasks vs raw createWithRawEdges."""

class CyclicDependencyError(Exception) {}

node Task {
    has tid: str;
    has depends_on: list[str] = {};
}

edge Dep {}
edge Need {}

def merge_first_win(specs: list[dict]) -> dict[str, list[str]] {
    merged: dict[str, list[str]] = {};
    for spec in specs {
        tid: str = spec["tid"] as str;
        deps: list[str] = spec["depends_on"] as list[str];
        if tid not in merged {
            merged[tid] = deps;
        }
    }
    return merged;
}

def merge_raw_maps(specs: list[dict]) -> tuple[dict[str, list[str]], dict[str, list[str]]] {
    nodes: dict[str, list[str]] = {};
    edges: dict[str, list[str]] = {};
    for spec in specs {
        tid: str = spec["tid"] as str;
        deps: list[str] = spec["depends_on"] as list[str];
        if tid not in nodes {
            nodes[tid] = deps;
        }
        edges[tid] = deps;
    }
    return (nodes, edges);
}

def edge_rows(dep_map: dict[str, list[str]]) -> list[list[str]] {
    rows: list[list[str]] = [];
    keys: list[str] = sorted(dep_map.keys());
    for tid in keys {
        dep_ids: list[str] = sorted(dep_map[tid]);
        for dep_id in dep_ids {
            row: list[str] = [dep_id, tid];
            rows.append(row);
        }
    }
    return rows;
}

def materialize_graph(dep_map: dict[str, list[str]]) -> Task {
    anchor: Task = Task(tid="__anchor__");
    id_map: dict[str, Task] = {};
    tids: list[str] = sorted(dep_map.keys());
    for tid in tids {
        nd: Task = Task(tid=tid, depends_on=dep_map[tid]);
        anchor ++> nd;
        id_map[tid] = nd;
    }
    for tid in tids {
        task_nd: Task = id_map[tid];
        for dep_id in dep_map[tid] {
            if dep_id in id_map {
                dep_nd: Task = id_map[dep_id];
                task_nd +>:Need:+> dep_nd;
                dep_nd +>:Dep:+> task_nd;
            }
        }
    }
    return anchor;
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has found_cycle: bool = False;

    can start with Task entry {
        if here.tid != "__anchor__" { skip; }
        kids: list[Task] = [here ->:Dep:->][?:Task];
        visit :0: kids;
        print(["cycle_probe", self.found_cycle]);
        disengage;
    }

    can walk with Task entry {
        if here.tid == "__anchor__" { skip; }
        if here.tid in self.claimed { skip; }
        if here.tid in self.stack and self.stack[here.tid] {
            self.found_cycle = True;
            skip;
        }
        self.stack[here.tid] = True;
        deps: list[Task] = [here ->:Need:+>][?:Task];
        visit :0: deps else { }
        self.stack[here.tid] = False;
        self.claimed[here.tid] = True;
    }
}

walker TopoOrder {
    has claimed: dict[str, bool] = {};
    has order: list[str] = {};

    can start with Task entry {
        if here.tid != "__anchor__" { skip; }
        kids: list[Task] = [here ->:Dep:->][?:Task];
        visit :0: kids;
        print(self.order);
        disengage;
    }

    can walk with Task entry {
        if here.tid == "__anchor__" { skip; }
        if here.tid in self.claimed { skip; }
        deps: list[Task] = [here ->:Need:+>][?:Task];
        visit :0: deps;
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
    }
}

def create_with_raw_edges(nodes: dict[str, list[str]], edges: dict[str, list[str]]) -> dict[str, any] {
    node_ids: list[str] = sorted(nodes.keys());
    dep_map: dict[str, list[str]] = edges;
    return {
        "nodes": node_ids,
        "edges": edge_rows(dep_map),
        "topo": [],
        "validated": False,
    };
}

def from_tasks(specs: list[dict[str, any]]) -> dict[str, any] {
    merged: dict[str, list[str]] = merge_first_win(specs);
    graph_root: Task = materialize_graph(merged);
    cp: CycleProbe = graph_root spawn CycleProbe();
    if cp.found_cycle {
        raise CyclicDependencyError();
    }
    tw: TopoOrder = graph_root spawn TopoOrder();
    return {
        "nodes": sorted(merged.keys()),
        "edges": edge_rows(merged),
        "topo": tw.order,
        "validated": True,
    };
}

def build_subgraph(specs: list[dict[str, any]]) -> dict[str, any] {
    return from_tasks(specs);
}

test "from_tasks_validates_dag" {
    specs: list[dict[str, any]] = [
        {"tid": "a", "depends_on": []},
        {"tid": "b", "depends_on": ["a"]},
        {"tid": "c", "depends_on": ["b"]},
    ];
    result: dict[str, any] = from_tasks(specs);
    assert (result["validated"] == True);
    assert (result["nodes"] == ["a", "b", "c"]);
    assert (result["edges"] == [["a", "b"], ["b", "c"]]);
    assert (result["topo"] == ["a", "b", "c"]);
}

test "from_tasks_rejects_cycle" {
    specs: list[dict[str, any]] = [
        {"tid": "a", "depends_on": ["b"]},
        {"tid": "b", "depends_on": ["a"]},
    ];
    raised: bool = False;
    try {
        from_tasks(specs);
    } except CyclicDependencyError {
        raised = True;
    }
    assert (raised == True);
}

test "create_with_raw_edges_skips_validation" {
    nodes: dict[str, list[str]] = {"x": [], "y": ["x"]};
    edges: dict[str, list[str]] = {"x": [], "y": ["x"], "z": ["y"]};
    result: dict[str, any] = create_with_raw_edges(nodes, edges);
    assert (result["validated"] == False);
    assert (result["nodes"] == ["x", "y"]);
    assert (result["edges"] == [["x", "y"], ["y", "z"]]);
    assert (result["topo"] == []);
}

test "build_subgraph_uses_validated_path" {
    specs: list[dict[str, any]] = [
        {"tid": "root", "depends_on": []},
        {"tid": "leaf", "depends_on": ["root"]},
    ];
    direct: dict[str, any] = from_tasks(specs);
    via_build: dict[str, any] = build_subgraph(specs);
    assert (via_build["validated"] == True);
    assert (via_build["nodes"] == direct["nodes"]);
    assert (via_build["edges"] == direct["edges"]);
    assert (via_build["topo"] == direct["topo"]);
}

test "merge_first_win_keeps_earliest_spec" {
    specs: list[dict[str, any]] = [
        {"tid": "t", "depends_on": ["a"]},
        {"tid": "t", "depends_on": ["b"]},
    ];
    merged: dict[str, list[str]] = merge_first_win(specs);
    result: dict[str, any] = from_tasks(specs);
    assert (merged["t"] == ["a"]);
    assert (result["edges"] == [["a", "t"]]);
}

test "edge_rows_sorted_deterministic" {
    dep_map: dict[str, list[str]] = {"b": ["z", "a"], "a": []};
    rows: list[list[str]] = edge_rows(dep_map);
    assert (rows == [["a", "b"], ["z", "b"]]);
}
