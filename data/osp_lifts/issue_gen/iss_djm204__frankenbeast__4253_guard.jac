"""djm204/frankenbeast#4253 — validated recursive subgraph; return from_tasks, not raw edges."""

glob CyclicDependencyError = Exception;

node PlanRoot {}

node Task {
    has cid: str;
}

edge Depends {}

walker TopoSort {
    has claimed: dict[str, bool] = {};
    has onstack: dict[str, bool] = {};
    has post: list[str] = [];
    has cyclic: bool = False;

    can start with PlanRoot entry {
        print "topo-start";
        kids: list[Task] = [here ->][?:Task];
        for nd in kids {
            visit :0: nd;
        }
        if len(kids) == 0 {
            disengage;
        }
    }

    can walk with Task entry {
        if here.cid in self.claimed {
            skip;
        }
        if here.cid in self.onstack {
            self.cyclic = True;
            print "cycle-detected";
            disengage;
        }
        self.onstack[here.cid] = True;
        deps: list[Task] = [here ->:Depends:->][?:Task];
        for dep in deps {
            visit :0: dep;
        }
        self.onstack[here.cid] = False;
        self.claimed[here.cid] = True;
        self.post.append(here.cid);
        print here.cid;
    }
}

def materialize_specs(specs: list) {
    store: dict[str, Task] = {};
    anchor = PlanRoot();
    root ++> anchor;
    for spec in specs {
        cid: str = spec["id"];
        if cid in store {
            raise CyclicDependencyError("duplicate id");
        }
        nd = Task(cid=cid);
        anchor ++> nd;
        store[cid] = nd;
    }
    for spec in specs {
        tgt: Task = store[spec["id"]] as Task;
        dep_ids: list = spec["dependsOn"];
        for dep_id in dep_ids {
            if dep_id not in store {
                raise CyclicDependencyError("missing dependency");
            }
            src: Task = store[dep_id] as Task;
            src +>:Depends:+> tgt;
        }
    }
}

def from_tasks(specs: list) -> list[str] {
    materialize_specs(specs);
    anchors: list[PlanRoot] = [root ->][?:PlanRoot];
    w = anchors[0] spawn TopoSort();
    if w.cyclic {
        raise CyclicDependencyError("cyclic dependency");
    }
    order: list[str] = [];
    i: int = len(w.post) - 1;
    while i >= 0 {
        order.append(w.post[i]);
        i -= 1;
    }
    return order;
}

def build_subgraph(specs: list) -> list[str] {
    # Fixed: assign and return validated topo order (not raw insertion escape hatch).
    return from_tasks(specs);
}

def raw_insertion_order(specs: list) -> list[str] {
    raw: list[str] = [];
    for spec in specs {
        raw.append(spec["id"]);
    }
    return raw;
}

test "linear_topo" {
    specs: list = [{"id": "a", "dependsOn": []}, {"id": "b", "dependsOn": ["a"]}];
    got: list[str] = from_tasks(specs);
    assert got == ["a", "b"];;
}

test "build_subgraph_validated" {
    specs: list = [
        {"id": "c", "dependsOn": ["a"]},
        {"id": "a", "dependsOn": []},
        {"id": "b", "dependsOn": ["a"]},
    ];
    got: list[str] = build_subgraph(specs);
    assert got == ["a", "b", "c"];;
}

test "diamond_topo" {
    specs: list = [
        {"id": "d", "dependsOn": ["b", "c"]},
        {"id": "b", "dependsOn": ["a"]},
        {"id": "c", "dependsOn": ["a"]},
        {"id": "a", "dependsOn": []},
    ];
    got: list[str] = from_tasks(specs);
    assert got == ["a", "b", "c", "d"];;
}

test "cycle_raises" {
    specs: list = [{"id": "a", "dependsOn": ["b"]}, {"id": "b", "dependsOn": ["a"]}];
    caught: bool = False;
    try {
        from_tasks(specs);
    } except CyclicDependencyError {
        caught = True;
    }
    assert caught;;
}

test "raw_insertion_order" {
    specs: list = [{"id": "c", "dependsOn": []}, {"id": "a", "dependsOn": []}];
    got: list[str] = raw_insertion_order(specs);
    assert got == ["c", "a"];;
}

test "duplicate_id_raises" {
    specs: list = [{"id": "a", "dependsOn": []}, {"id": "a", "dependsOn": []}];
    caught: bool = False;
    try {
        materialize_specs(specs);
    } except CyclicDependencyError {
        caught = True;
    }
    assert caught;;
}
