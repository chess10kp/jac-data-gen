"""ADC-Consulting/rosetta-decode#69 — data lineage DAG for cloud workflow tasks."""

node Task {
    has name: str;
}

edge UpstreamOf {}

obj Pipeline {
    has tasks: dict[str, Task] = {};
}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Task entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:UpstreamOf:->][?:Task];
    }
}

def load_pipeline(tasks: list[str], edges: list[tuple[str, str]]) -> Pipeline {
    p = Pipeline();
    for t in tasks {
        nd = Task(name=t);
        root ++> nd;
        p.tasks[t] = nd;
    }
    for (up, down) in edges {
        u = p.tasks.get(up, None);
        d = p.tasks.get(down, None);
        if u is not None and d is not None { d +>:UpstreamOf:+> u; }
    }
    return p;
}

def upstream_tasks(store: Pipeline, task: str) -> list[str] {
    nd = store.tasks.get(task, None);
    if nd is None { return []; }
    w = nd spawn UpstreamWalk(claimed={}, reached=[]);
    out: list[str] = [];
    for n in w.reached {
        if n != task { out.append(n); }
    }
    return sorted(out);
}

def lineage_depth(store: Pipeline, task: str) -> int {
    nd = store.tasks.get(task, None);
    if nd is None { return -1; }
    depth: dict[str, int] = {task: 0};
    frontier: list[Task] = [nd];
    best = 0;
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        for u in [cur ->:UpstreamOf:->][?:Task] {
            nd2 = depth[cur.name] + 1;
            if nd2 > best { best = nd2; }
            if not (u.name in depth) or nd2 > depth[u.name] {
                depth[u.name] = nd2;
                frontier.append(u);
            }
        }
    }
    return best;
}
