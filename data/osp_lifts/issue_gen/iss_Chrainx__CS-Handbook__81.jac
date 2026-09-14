# Chrainx/CS-Handbook#81

node Workflow {
    has title: str = "workflow";
}

node Task {
    has cid: str;
}

node SortStep {
    has kind: str;
    has cid: str = "";
}

edge Contains {}
edge Depends {}

walker CollectTasks {
    has claimed: dict[str, bool] = {};
    has found: list[Task] = [];

    can collect_workflow with Workflow entry {
        print("topological sort");
        for task in [here ->:Contains:->][?:Task] {
            visit :0: [task];
        }
    }

    can collect_task with Task entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here);
        print(here.cid);
        for dependency in [here ->:Depends:->][?:Task] {
            visit :0: [dependency];
        }
    }
}

def _findTask(graph: Workflow, cid: str) -> Task | None {
    for task in [graph ->:Contains:->][?:Task] {
        if task.cid == cid {
            return task;
        }
    }
    return None;
}

def newWorkflow(ids: list[str]) -> Workflow {
    graph = Workflow();
    for cid in ids {
        task = Task(cid=cid);
        graph +>:Contains:+> task;
    }
    return graph;
}

def addDependency(graph: Workflow, source_id: str, target_id: str) -> None {
    source = _findTask(graph, source_id);
    target = _findTask(graph, target_id);
    if source is not None and target is not None {
        source +>:Depends:+> target;
    }
    return None;
}

def topologicalSortSteps(graph: Workflow) -> list[SortStep] {
    steps: list[SortStep] = [];
    w = graph spawn CollectTasks(claimed={});
    tasks: list[Task] = w.found;
    ordered: list[Task] = [];
    changed: bool = True;

    while changed {
        changed = False;
        for task in tasks {
            if task in ordered {
                continue;
            }
            ready: bool = True;
            for dependency in [task ->:Depends:->][?:Task] {
                if dependency not in ordered {
                    ready = False;
                }
            }
            if ready {
                ordered.append(task);
                changed = True;
            }
        }
    }

    for task in ordered {
        steps.append(SortStep(kind="mark-visited", cid=task.cid));
    }
    if len(ordered) < len(tasks) {
        steps.append(SortStep(kind="cycle-detected"));
    }
    return steps;
}

def deriveTopoOrder(steps: list[SortStep]) -> list[str] {
    order: list[str] = [];
    for step in steps {
        if step.kind == "mark-visited" {
            order.append(step.cid);
        }
    }
    return order;
}
