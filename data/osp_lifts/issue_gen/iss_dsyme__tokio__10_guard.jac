"""Guard: dsyme/tokio#10."""

node TaskNode { has name: str; }
edge Spawns {}

obj TaskGraph { has tasks: dict[str, TaskNode] = {}; }

walker SpawnReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with TaskNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Spawns:->][?:TaskNode];
    }
}

def load_task_graph(
    tasks: list[str],
    spawn_edges: list[tuple[str, str]],
) -> TaskGraph {
    g = TaskGraph();
    for t in tasks {
        nd = TaskNode(name=t);
        root ++> nd;
        g.tasks[t] = nd;
    }
    for (parent, child) in spawn_edges {
        p = g.tasks.get(parent, None);
        c = g.tasks.get(child, None);
        if p is not None and c is not None { p +>:Spawns:+> c; }
    }
    return g;
}

def reachable_tasks(graph: TaskGraph, `root: str) -> list[str] {
    nd = graph.tasks.get(`root, None);
    if nd is None { return []; }
    w = nd spawn SpawnReach(claimed={}, reached=[]);
    return sorted(w.reached);
}

def spawn_depth_within(graph: TaskGraph, `root: str, limit: int) -> bool {
    nd = graph.tasks.get(`root, None);
    if nd is None { return False; }
    depth: dict[str, int] = {`root: 0};
    frontier: list[TaskNode] = [nd];
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        cur_depth = depth[cur.name];
        for nxt in [cur ->:Spawns:->][?:TaskNode] {
            next_depth = cur_depth + 1;
            if next_depth > limit { return False; }
            if not (nxt.name in depth) or next_depth > depth[nxt.name] {
                depth[nxt.name] = next_depth;
                frontier.append(nxt);
            }
        }
    }
    return True;
}

def orphan_tasks(graph: TaskGraph, roots: list[str]) -> list[str] {
    reachable: dict[str, bool] = {};
    for r in roots {
        for t in reachable_tasks(graph, r) { reachable[t] = True; }
    }
    out: list[str] = [];
    for k in graph.tasks.keys() {
        if not (k in reachable) { out.append(k); }
    }
    return sorted(out);
}

test "spawn reachability" {
    g = load_task_graph(
        ["rt", "worker", "io", "timer"],
        [("rt", "worker"), ("rt", "io"), ("worker", "timer")],
    );
    assert reachable_tasks(g, "rt") == ["io", "rt", "timer", "worker"];
    assert spawn_depth_within(g, "rt", 3);
    assert orphan_tasks(g, ["rt"]) == [];
}

test "diamond adversarial revisit" {
    g = load_task_graph(
        ["hub", "left", "right", "leaf"],
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    );
    assert reachable_tasks(g, "hub") == ["hub", "leaf", "left", "right"];
}
