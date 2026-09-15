"""djm204/frankenbeast#4363 PlanGraph sub-graph dependsOn consistency."""

node PlanRoot {
    has reason: str = "";
}

node Task {
    has tid: str;
    has depends_on: list[str] = [];
}

edge Depends {}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has cycle: bool = False;

    can begin with PlanRoot entry {
        kids: list[Task] = [];
        for ch in [here ->+:Task] {
            kids.append(ch);
        }
        print {"cycle_probe": "start"};
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }

    can step with Task entry {
        if here.tid in self.claimed {
            self.cycle = True;
            print {"cycle_hit": here.tid};
            skip;
        }
        self.claimed[here.tid] = True;
        print {"cycle_visit": here.tid};
        kids: list[Task] = [];
        for ch in [here ->:Depends:->][?:Task] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker Collect {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can begin with PlanRoot entry {
        kids: list[Task] = [];
        for ch in [here ->+:Task] {
            kids.append(ch);
        }
        print {"collect_probe": "start"};
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }

    can step with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        print {"collect": here.tid};
        kids: list[Task] = [];
        for ch in [here ->:Depends:->][?:Task] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker Bootstrap {
    can boot with entry {
        sample: list = [
            {"id": "a", "depends_on": []},
            {"id": "b", "depends_on": ["a"]},
        ];
        out = from_tasks(sample, "recursive expansion");
        print {"bootstrap": out};
        disengage;
    }
}

def attach_tasks(graph_root: PlanRoot, specs: list) -> dict[str, Task] {
    index: dict[str, Task] = {};
    for spec in specs {
        tid = spec["id"];
        raw: list[str] = [];
        if "depends_on" in spec {
            dep_list = spec["depends_on"] as list;
            for d in dep_list {
                raw.append(d);
            }
        }
        nd = Task(tid=tid, depends_on=raw);
        graph_root ++> nd;
        index[tid] = nd;
    }
    for spec in specs {
        tid = spec["id"];
        t = index[tid];
        deps: list[str] = [];
        if "depends_on" in spec {
            dep_list = spec["depends_on"] as list;
            for d in dep_list {
                deps.append(d);
            }
        }
        for dep in deps {
            if dep not in index {
                raise ValueError("unknown dependency");
            }
            dep_node = index[dep];
            dep_node +>:Depends:+> t;
        }
    }
    return index;
}

def materialize(index: dict[str, Task], reason: str) -> dict {
    ids: list[str] = [];
    for k in index {
        ids.append(k);
    }
    ids = sorted(ids);
    nodes_out: dict = {};
    edges_out: list[list[str]] = [];
    for tid in ids {
        t = index[tid];
        preds: list[Task] = [];
        for p in [t <-:Depends:<-][?:Task] {
            preds.append(p);
        }
        deps: list[str] = [];
        for p in preds {
            edges_out.append([p.tid, t.tid]);
            deps.append(p.tid);
        }
        nodes_out[tid] = {"id": tid, "depends_on": sorted(deps)};
    }
    edges_sorted: list[list[str]] = [];
    for e in sorted(edges_out) {
        edges_sorted.append(e);
    }
    return {"reason": reason, "nodes": nodes_out, "edges": edges_sorted};
}

def from_tasks(tasks: list, reason: str = "") -> dict {
    graph_root = PlanRoot(reason=reason);
    root ++> graph_root;
    index: dict[str, Task] = attach_tasks(graph_root, tasks);
    w = graph_root spawn CycleProbe(claimed={});
    if w.cycle {
        raise ValueError("cycle detected");
    }
    return materialize(index, reason);
}

def build_sub_graph(tasks: list, completed: list | None = None, reason: str = "") -> dict {
    completed_set: dict[str, bool] = {};
    if completed {
        for c in completed {
            completed_set[c] = True;
        }
    }
    task_ids: dict[str, bool] = {};
    for t in tasks {
        task_ids[t["id"]] = True;
    }
    internal: list = [];
    for t in tasks {
        tid = t["id"];
        internal_deps: list[str] = [];
        raw_deps: list[str] = [];
        if "depends_on" in t {
            dep_list = t["depends_on"] as list;
            for d in dep_list {
                raw_deps.append(d);
            }
        }
        for dep in raw_deps {
            if dep in task_ids and dep not in completed_set {
                internal_deps.append(dep);
            }
        }
        internal.append({"id": tid, "depends_on": internal_deps});
    }
    return from_tasks(internal, reason);
}

def get_dependencies(graph: dict, task_id: str) -> list {
    edges = graph["edges"] as list;
    out: list[str] = [];
    for e in edges {
        pair = e as list;
        if pair[1] == task_id {
            out.append(pair[0]);
        }
    }
    return sorted(out);
}

def get_node_depends_on(graph: dict, task_id: str) -> list[str] {
    nodes = graph["nodes"] as dict;
    node = nodes[task_id] as dict;
    deps = node["depends_on"] as list;
    out: list[str] = [];
    for d in deps {
        out.append(d);
    }
    return sorted(out);
}

with entry {
    root spawn Bootstrap();
}
