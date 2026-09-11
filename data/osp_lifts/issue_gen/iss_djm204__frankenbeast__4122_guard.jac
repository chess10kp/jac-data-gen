"""Guard: djm204/frankenbeast#4122."""

class CyclicDependencyError(Exception) {}
obj PlanGraph { has tasks: dict[str, PlanTask] = {}; }
node PlanTask { has tid: str; }
edge DependsOn {}

def load_plan(
    tasks: list[str],
    edges: list[tuple[str, str]],
) -> PlanGraph {
    g = PlanGraph();
    for tid in tasks {
        if tid not in g.tasks {
            nd = PlanTask(tid=tid);
            root ++> nd;
            g.tasks[tid] = nd;
        }
    }
    for (task, dep) in edges {
        a = g.tasks.get(task, None);
        b = g.tasks.get(dep, None);
        if a is not None and b is not None { a +>:DependsOn:+> b; }
    }
    return g;
}

def validate_plan(g: PlanGraph) -> list[str] {
    indeg: dict[str, int] = {};
    for tid in g.tasks.keys() {
        nd = g.tasks.get(tid, None);
        if nd is None { indeg[tid] = 0; }
        else { indeg[tid] = len([nd ->:DependsOn:->][?:PlanTask]); }
    }
    ready = sorted([tid for tid in g.tasks.keys() if indeg.get(tid, 0) == 0]);
    order: list[str] = [];
    while ready {
        cur = ready.pop(0);
        order.append(cur);
        nd = g.tasks.get(cur, None);
        if nd is None { continue; }
        for task in [nd <-:DependsOn:<-][?:PlanTask] {
            indeg[task.tid] -= 1;
            if indeg[task.tid] == 0 { ready.append(task.tid); }
        }
        ready = sorted(ready);
    }
    if len(order) != len(g.tasks) { raise CyclicDependencyError("cyclic sub-graph"); }
    return order;
}

def build_subgraph(g: PlanGraph, task_ids: list[str]) -> list[str] {
    keep: dict[str, bool] = {};
    for tid in task_ids {
        if tid in g.tasks { keep[tid] = True; }
    }
    sub = PlanGraph();
    for tid in g.tasks.keys() {
        if tid not in keep { continue; }
        nd = PlanTask(tid=tid);
        root ++> nd;
        sub.tasks[tid] = nd;
    }
    for tid in g.tasks.keys() {
        if tid not in keep { continue; }
        src = sub.tasks.get(tid, None);
        task = g.tasks.get(tid, None);
        if src is None or task is None { continue; }
        for dep in [task ->:DependsOn:->][?:PlanTask] {
            if dep.tid in keep {
                dst = sub.tasks.get(dep.tid, None);
                if dst is not None { src +>:DependsOn:+> dst; }
            }
        }
    }
    return validate_plan(sub);
}

test "linear plan validates in dependency order" {
    g = load_plan(
        ["a", "b", "c", "d"],
        [("b", "a"), ("c", "b"), ("d", "c")],
    );
    assert validate_plan(g) == ["a", "b", "c", "d"];
    assert build_subgraph(g, ["b", "c", "d"]) == ["b", "c", "d"];
}

test "cyclic sub-graph raises" {
    g = load_plan(
        ["x", "y", "z"],
        [("x", "y"), ("y", "z"), ("z", "x")],
    );
    raised = False;
    try { validate_plan(g); }
    except CyclicDependencyError { raised = True; }
    assert raised;
}

test "diamond merge validates deterministically" {
    g = load_plan(
        ["root", "left", "right", "merge"],
        [("left", "root"), ("right", "root"), ("merge", "left"), ("merge", "right")],
    );
    assert validate_plan(g) == ["root", "left", "right", "merge"];
}

test "empty subgraph tolerant" {
    g = load_plan(["a"], []);
    assert build_subgraph(g, ["missing"]) == [];
}
