"""ed3c/ai-edge-tlm#15 — Foundation DAG validation and reachability."""

node Task {
    has tid: str;
}

edge DependsOn {}

obj DagStore {
    has tasks: dict[str, Task] = {};
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        visit [<-:DependsOn:<-][?:Task];
    }
}

walker CycleWalk {
    has claimed: dict[str, bool] = {};
    has cyclic: bool = False;

    can step with Task entry {
        if here.tid in self.claimed {
            self.cyclic = True;
            disengage;
        }
        self.claimed[here.tid] = True;
        visit [->:DependsOn:->][?:Task];
    }
}

def load_dag(
    node_ids: list[str],
    depends_edges: list[tuple[str, str]],
) -> DagStore {
    dag = DagStore();
    for nid in node_ids {
        nd = Task(tid=nid);
        root ++> nd;
        dag.tasks[nid] = nd;
    }
    for (upstream, downstream) in depends_edges {
        u = dag.tasks.get(upstream, None);
        d = dag.tasks.get(downstream, None);
        if u is not None and d is not None { d +>:DependsOn:+> u; }
    }
    return dag;
}

def validate_dag(store: DagStore) -> list[tuple[str, str]] {
    if has_cycle(store) { return [("cycle", "detected")]; }
    return [];
}

def reachable_from(store: DagStore, start: str) -> list[str] {
    nd = store.tasks.get(start, None);
    if nd is None { return []; }
    w = nd spawn ReachWalk(claimed={});
    return sorted(w.found);
}

def has_cycle(store: DagStore) -> bool {
    for tid in store.tasks {
        nd = store.tasks[tid];
        w = nd spawn CycleWalk(claimed={}, cyclic=False);
        if w.cyclic { return True; }
    }
    return False;
}
