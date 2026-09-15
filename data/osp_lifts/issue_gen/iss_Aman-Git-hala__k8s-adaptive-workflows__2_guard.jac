"""DAG workflow cycle detection — Aman-Git-hala/k8s-adaptive-workflows#2."""

node Workflow {
    has tasks: dict[str, Task] = {};
}

node Task {
    has tid: str;
}

edge Depends {}

def create_workflow -> Workflow {
    wf = Workflow();
    root ++> wf;
    return wf;
}

def ensure_task(wf: Workflow, tid: str) -> Task {
    if tid in wf.tasks {
        return wf.tasks[tid] as Task;
    }
    t = Task(tid=tid);
    wf ++> t;
    wf.tasks[tid] = t;
    return t;
}

def get_task(wf: Workflow, tid: str) -> Task | None {
    if tid in wf.tasks {
        return wf.tasks[tid] as Task;
    }
    return None;
}

def add_dependency(wf: Workflow, pred: str, succ: str) {
    pred_node = ensure_task(wf, pred);
    succ_node = ensure_task(wf, succ);
    has_dep: bool = False;
    for ch in [pred_node ->:Depends:->][?:Task] {
        if ch.tid == succ {
            has_dep = True;
        }
    }
    if !has_dep {
        pred_node +>:Depends:+> succ_node;
    }
}

walker CycleDetector {
    has claimed: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has found: bool = False;
    has cycle_nodes: list[str] = {};

    can probe with Task entry {
        if self.found {
            skip;
        }
        if here.tid in self.stack {
            self.found = True;
            self.cycle_nodes.append(here.tid);
            print(f"back-edge at {here.tid}");
            skip;
        }
        if here.tid in self.claimed {
            skip;
        }
        self.stack[here.tid] = True;
        nexts: list[Task] = [];
        for ch in [here ->:Depends:->][?:Task] {
            nexts.append(ch);
        }
        for nxt in nexts {
            visit [nxt];
        }
        self.stack[here.tid] = False;
        self.claimed[here.tid] = True;
    }
}

def has_cycle(wf: Workflow) -> bool {
    all_tasks: list[Task] = [];
    for t in [wf-->(`?Task)] {
        all_tasks.append(t);
    }
    claimed: dict[str, bool] = {};
    for t in all_tasks {
        if t.tid in claimed {
            continue;
        }
        stack: dict[str, bool] = {};
        cycle_nodes: list[str] = {};
        w = t spawn CycleDetector(
            claimed=claimed, stack=stack, found=False, cycle_nodes=cycle_nodes
        );
        print(f"component {t.tid} found={w.found}");
        if w.found {
            return True;
        }
    }
    return False;
}

def validate_dag(wf: Workflow) -> bool {
    return !has_cycle(wf);
}

test "empty workflow is valid dag" {
    wf = create_workflow();
    assert !has_cycle(wf);
    assert validate_dag(wf);
}

test "linear chain no cycle" {
    wf = create_workflow();
    add_dependency(wf, "fetch", "build");
    add_dependency(wf, "build", "deploy");
    assert !has_cycle(wf);
    assert validate_dag(wf);
}

test "triangle cycle detected" {
    wf = create_workflow();
    add_dependency(wf, "a", "b");
    add_dependency(wf, "b", "c");
    add_dependency(wf, "c", "a");
    assert has_cycle(wf);
    assert !validate_dag(wf);
}

test "duplicate dependency is idempotent" {
    wf = create_workflow();
    add_dependency(wf, "a", "b");
    add_dependency(wf, "a", "b");
    assert !has_cycle(wf);
    assert validate_dag(wf);
}

test "get_task resolves and misses" {
    wf = create_workflow();
    add_dependency(wf, "alpha", "beta");
    got = get_task(wf, "alpha");
    assert got is not None;
    assert got.tid == "alpha";
    assert get_task(wf, "missing") is None;
}

test "diamond acyclic" {
    wf = create_workflow();
    add_dependency(wf, "root", "left");
    add_dependency(wf, "root", "right");
    add_dependency(wf, "left", "sink");
    add_dependency(wf, "right", "sink");
    assert !has_cycle(wf);
    assert validate_dag(wf);
}
