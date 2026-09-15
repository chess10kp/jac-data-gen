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
