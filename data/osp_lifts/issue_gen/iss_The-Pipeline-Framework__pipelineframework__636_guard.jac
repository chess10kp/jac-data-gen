"""The-Pipeline-Framework/pipelineframework#636 — recursive agent pipeline composition."""

node PipelineStep {
    has name: str;
}

edge ChildOf {}

edge Spawns {}

edge DependsOn {}

obj PipelineStore {
    has steps: dict[str, PipelineStep] = {};
    has turn_budget: int = 0;
}

walker SpawnReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with PipelineStep entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Spawns:->][?:PipelineStep];
    }
}

walker UnblockReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with PipelineStep entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [<-:DependsOn:<-][?:PipelineStep];
    }
}

def load_pipeline(
    steps: list[tuple[str, str | None]],
    spawn_edges: list[tuple[str, str]],
    depends_edges: list[tuple[str, str]],
    turn_budget: int,
) -> PipelineStore {
    store = PipelineStore(turn_budget=turn_budget if turn_budget > 0 else 0);
    for (name, parent) in steps {
        nd = PipelineStep(name=name);
        root ++> nd;
        store.steps[name] = nd;
        if parent is not None {
            p = store.steps.get(parent, None);
            if p is not None { p +>:ChildOf:+> nd; }
        }
    }
    for (caller, callee) in spawn_edges {
        c = store.steps.get(caller, None);
        d = store.steps.get(callee, None);
        if c is not None and d is not None { c +>:Spawns:+> d; }
    }
    for (upstream, downstream) in depends_edges {
        u = store.steps.get(upstream, None);
        d = store.steps.get(downstream, None);
        if u is not None and d is not None { d +>:DependsOn:+> u; }
    }
    return store;
}

def ancestor_chain(store: PipelineStore, step: str) -> list[str] {
    nd = store.steps.get(step, None);
    if nd is None { return []; }
    chain: list[str] = [];
    cur: PipelineStep | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.name in seen { break; }
        seen[cur.name] = True;
        chain.append(cur.name);
        parent: PipelineStep | None = None;
        for p in [cur <-:ChildOf:<-][?:PipelineStep] {
            parent = p;
            break;
        }
        cur = parent;
    }
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

def reachable_via_spawn(store: PipelineStore, step: str) -> list[str] {
    nd = store.steps.get(step, None);
    if nd is None { return []; }
    w = nd spawn SpawnReach(claimed={}, reached=[]);
    return sorted(w.reached);
}

def ready_after_deps(store: PipelineStore, completed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in completed { done[c] = True; }
    out: list[str] = [];
    for sid in sorted(store.steps.keys()) {
        if sid in done { continue; }
        nd = store.steps[sid];
        ok = True;
        for up in [nd ->:DependsOn:->][?:PipelineStep] {
            if not (up.name in done) { ok = False; }
        }
        if ok { out.append(sid); }
    }
    return out;
}

def bounded_turns(store: PipelineStore, start: str) -> list[str] {
    nd = store.steps.get(start, None);
    if nd is None { return []; }
    path: list[str] = [start];
    cur = start;
    for _ in range(store.turn_budget) {
        nxt_list: list[str] = [];
        cnd = store.steps.get(cur, None);
        if cnd is not None {
            for tgt in [cnd ->:Spawns:->][?:PipelineStep] {
                nxt_list.append(tgt.name);
            }
        }
        if len(nxt_list) == 0 { break; }
        nxt_list.sort();
        cur = nxt_list[0];
        path.append(cur);
    }
    return path;
}

test "pipeline composition" {
    store = load_pipeline(
        [("state", None), ("query", "state"), ("decide", "query"), ("observe", "decide"), ("complete", "observe")],
        [("state", "query"), ("query", "decide"), ("decide", "observe"), ("observe", "complete")],
        [("state", "query"), ("query", "decide"), ("decide", "observe"), ("observe", "complete")],
        3,
    );
    assert ancestor_chain(store, "complete") == ["state", "query", "decide", "observe", "complete"];
    assert reachable_via_spawn(store, "state") == ["complete", "decide", "observe", "query", "state"];
    assert ready_after_deps(store, ["state", "query"]) == ["decide"];
    assert bounded_turns(store, "state") == ["state", "query", "decide", "observe"];
}
