"""chrislyclau/copilot-ui#414 — Task dependency graph + Planner decomposition."""

glob CYCLE_WALK_LIMIT: int = 64;

obj PlannerGraph { has tasks: dict[str, Task] = {}; }
node Task { has tid: str; }
edge ChildOf {}
edge Blocks {}

walker SubtreeWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    can step with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.hits.append(here.tid);
        visit [->:ChildOf:->][?:Task];
    }
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    can step with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.hits.append(here.tid);
        visit [->:Blocks:->][?:Task];
    }
}

walker CycleProbe {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: bool = False;
    has steps: int = 0;
    can step with Task entry {
        if here.tid == self.target { self.found = True; disengage; }
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.steps += 1;
        if self.steps >= CYCLE_WALK_LIMIT { disengage; }
        visit [->:Blocks:->][?:Task];
    }
}

def load_planner(
    tasks: list[str],
    parent_edges: list[tuple[str, str]],
    deps: list[tuple[str, str]] | None = None,
) -> PlannerGraph {
    g = PlannerGraph();
    for tid in tasks {
        if tid not in g.tasks {
            nd = Task(tid=tid);
            root ++> nd;
            g.tasks[tid] = nd;
        }
    }
    for (child, parent) in parent_edges {
        p = g.tasks.get(parent, None);
        c = g.tasks.get(child, None);
        if p is None { continue; }
        if c is None { continue; }
        p +>:ChildOf:+> c;
    }
    for (blocker, dependent) in deps or [] {
        b = g.tasks.get(blocker, None);
        d = g.tasks.get(dependent, None);
        if b is None { continue; }
        if d is None { continue; }
        b +>:Blocks:+> d;
    }
    return g;
}

def add_dependency(g: PlannerGraph, blocker: str, dependent: str) {
    bt = g.tasks.get(blocker, None);
    dt = g.tasks.get(dependent, None);
    if bt is None or dt is None { raise KeyError("unknown task"); }
    if blocker == dependent { raise ValueError("self edge"); }
    dup = False;
    for h in [dt <-:Blocks:<-][?:Task] {
        if h.tid == blocker { dup = True; }
    }
    if dup { raise ValueError("duplicate edge"); }
    w = dt spawn CycleProbe(claimed={}, target=blocker);
    if w.found { raise ValueError("cycle"); }
    bt +>:Blocks:+> dt;
}

def remove_dependency(g: PlannerGraph, blocker: str, dependent: str) {
    if dependent not in g.tasks { raise KeyError("unknown task"); }
    bt = g.tasks.get(blocker, None);
    dt = g.tasks.get(dependent, None);
    if bt is None or dt is None { return; }
    bt del ->:Blocks:-> dt;
}

def is_blocked(
    g: PlannerGraph,
    task_id: str,
    statuses: dict[str, str],
    read_error: bool = False,
) -> bool {
    if read_error { return True; }
    nd = g.tasks.get(task_id, None);
    if nd is None { return True; }
    for blk in [nd <-:Blocks:<-][?:Task] {
        if statuses.get(blk.tid) != "done" { return True; }
    }
    return False;
}

def subtree_tasks(g: PlannerGraph, root_id: str) -> list[str] {
    if root_id not in g.tasks { return []; }
    start = g.tasks[root_id];
    if start is None { return []; }
    w = start spawn SubtreeWalk();
    return sorted(w.hits);
}

def dependent_closure(g: PlannerGraph, task_id: str) -> list[str] {
    start = g.tasks.get(task_id, None);
    if start is None { return []; }
    w = start spawn DownstreamWalk();
    return sorted(w.hits);
}
