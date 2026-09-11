"""DonTizi/CodeGeass#2 — task DAG cycle detection and ready frontier."""

node Task {
    has tid: str;
}

edge Blocks {}

obj TaskGraph {
    has tasks: dict[str, Task] = {};
    has done: dict[str, bool] = {};
}

def load_tasks(
    tasks: list[str],
    edges: list[tuple[str, str]],
    done: list[str] | None = None,
) -> TaskGraph {
    g = TaskGraph();
    for tid in tasks {
        nd = Task(tid=tid);
        root ++> nd;
        g.tasks[tid] = nd;
    }
    for (blocker, blocked) in edges {
        b = g.tasks.get(blocker, None);
        t = g.tasks.get(blocked, None);
        if b is not None and t is not None { t +>:Blocks:+> b; }
    }
    if done is not None {
        for d in done { g.done[d] = True; }
    }
    return g;
}

walker CycleProbe {
    has target: str = "";
    has path: list[str] = [];
    has found: bool = False;
    can step with Task entry {
        if here.tid in self.path {
            if here.tid == self.target and len(self.path) > 0 { self.found = True; }
            skip;
        }
        self.path = self.path + [here.tid];
        if len(self.path) > 1 and here.tid == self.target { self.found = True; disengage; }
        visit [->:Blocks:->][?:Task];
    }
}

def has_cycle(store: TaskGraph) -> bool {
    for (tid, nd) in store.tasks.items() {
        w = nd spawn CycleProbe(target=tid, path=[], found=False);
        if w.found { return True; }
    }
    return False;
}

def ready_tasks(store: TaskGraph) -> list[str] {
    out: list[str] = [];
    for tid in sorted(store.tasks.keys()) {
        if tid in store.done { continue; }
        nd = store.tasks[tid];
        ok = True;
        for blk in [nd ->:Blocks:->][?:Task] {
            if blk.tid not in store.done { ok = False; }
        }
        if ok { out.append(tid); }
    }
    return out;
}
