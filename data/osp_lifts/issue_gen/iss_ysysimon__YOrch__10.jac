"""ysysimon/YOrch#10 — Task DAG compile planning."""

obj TaskGraph { has tasks: dict[str, Task] = {}; }
node Task { has tid: str; }
edge DependsOn {}

def load_task_graph(
    tasks: list[str],
    depends: list[tuple[str, str]],
) -> TaskGraph {
    g = TaskGraph();
    for t in tasks {
        if t not in g.tasks {
            nd = Task(tid=t);
            root ++> nd;
            g.tasks[t] = nd;
        }
    }
    for (task, dep) in depends {
        tgt = g.tasks.get(task, None);
        if tgt is None { continue; }
        src = g.tasks.get(dep, None);
        if src is None { raise KeyError("invalid dependency: " + dep); }
        src +>:DependsOn:+> tgt;
    }
    return g;
}

def compile_plan(g: TaskGraph) -> list[str] {
    indeg: dict[str, int] = {};
    for (tid, nd) in g.tasks.items() {
        indeg[tid] = len([nd <-:DependsOn:<-][?:Task]);
    }
    ready = sorted([t for (t, d) in indeg.items() if d == 0]);
    out: list[str] = [];
    while ready {
        cur = ready.pop(0);
        out.append(cur);
        nd = g.tasks.get(cur, None);
        if nd is None { continue; }
        for dep in [nd ->:DependsOn:->][?:Task] {
            indeg[dep.tid] -= 1;
            if indeg[dep.tid] == 0 { ready.append(dep.tid); }
        }
        ready = sorted(ready);
    }
    if len(out) != len(g.tasks) { raise ValueError("cycle"); }
    return out;
}

def ready_after(g: TaskGraph, completed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in completed { done[c] = True; }
    out: list[str] = [];
    for tid in sorted(g.tasks.keys()) {
        if tid in done { continue; }
        nd = g.tasks.get(tid, None);
        if nd is None { continue; }
        prereqs = [n.tid for n in [nd <-:DependsOn:<-][?:Task]];
        ok = True;
        for p in prereqs { if p not in done { ok = False; } }
        if ok { out.append(tid); }
    }
    return out;
}
