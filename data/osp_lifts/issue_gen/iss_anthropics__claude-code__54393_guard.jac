"""anthropics/claude-code#54393 — overnight multi-agent coordination cascade failures."""

node Task {
    has tid: str;
    has failed: bool = False;
}

node Agent {
    has aid: str;
}

edge Depends {}
edge Dispatches {}

obj CoordHandle {
    has task_index: dict[str, Task] = {};
    has agent_index: dict[str, Agent] = {};
}

def attach_task(handle: CoordHandle, tid: str, failed: bool = False) -> Task {
    nd = Task(tid=tid, failed=failed);
    handle.task_index[tid] = nd;
    root ++> nd;
    return nd;
}

def attach_agent(handle: CoordHandle, aid: str) -> Agent {
    nd = Agent(aid=aid);
    handle.agent_index[aid] = nd;
    root ++> nd;
    return nd;
}

def link_depends(upstream: Task, downstream: Task) -> None {
    upstream +>:Depends:+> downstream;
}

def link_dispatch(coordinator: Agent, worker: Agent) -> None {
    coordinator +>:Dispatches:+> worker;
}

walker DownstreamCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can collect with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        print("downstream", here.tid);
        kids: list[Task] = [];
        for ch in [here ->:Depends:->][?:Task] {
            kids.append(ch);
        }
        visit :0: kids else { disengage; }
    }
}

def collect_downstream(seed: str, handle: CoordHandle) -> list[str] {
    if seed not in handle.task_index {
        return [];
    }
    seed_node = handle.task_index[seed];
    w = seed_node spawn DownstreamCollect(claimed={});
    w.collect();
    return sorted(w.found);
}

walker DispatchWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can dispatch with Agent entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        self.order.append(here.aid);
        print("dispatch", here.aid);
        kids: list[Agent] = [];
        for ch in [here ->:Dispatches:->][?:Agent] {
            kids.append(ch);
        }
        visit :0: kids else { disengage; }
    }
}

def dispatch_closure(coordinator: str, handle: CoordHandle) -> list[str] {
    if coordinator not in handle.agent_index {
        return [];
    }
    coord = handle.agent_index[coordinator];
    w = coord spawn DispatchWalk(claimed={});
    w.dispatch();
    return sorted(w.order);
}

def cascade_failed_tasks(seeds: list[str], handle: CoordHandle) -> list[str] {
    hits: dict[str, bool] = {};
    for seed in seeds {
        if seed not in handle.task_index {
            continue;
        }
        reachable = collect_downstream(seed, handle);
        for tid in reachable {
            task = handle.task_index[tid];
            if task.failed {
                hits[tid] = True;
            }
        }
    }
    out: list[str] = [];
    for tid in hits {
        out.append(tid);
    }
    return sorted(out);
}

test "unknown_seed_empty" {
    h = CoordHandle();
    got = collect_downstream("missing", h);
    assert got == [];
}

test "downstream_chain_sorted" {
    h = CoordHandle();
    t1 = attach_task(h, "t1");
    t2 = attach_task(h, "t2");
    t3 = attach_task(h, "t3");
    link_depends(t1, t2);
    link_depends(t2, t3);
    got = collect_downstream("t1", h);
    assert got == ["t1", "t2", "t3"];
}

test "downstream_cycle_claim_skip" {
    h = CoordHandle();
    a = attach_task(h, "a");
    b = attach_task(h, "b");
    c = attach_task(h, "c");
    link_depends(a, b);
    link_depends(b, c);
    link_depends(c, a);
    got = collect_downstream("a", h);
    assert got == ["a", "b", "c"];
}

test "dispatch_unknown_empty" {
    h = CoordHandle();
    got = dispatch_closure("ghost", h);
    assert got == [];
}

test "dispatch_closure_sorted" {
    h = CoordHandle();
    c = attach_agent(h, "coord");
    w1 = attach_agent(h, "w1");
    w2 = attach_agent(h, "w2");
    link_dispatch(c, w1);
    link_dispatch(c, w2);
    link_dispatch(w1, w2);
    got = dispatch_closure("coord", h);
    assert got == ["coord", "w1", "w2"];
}

test "cascade_failed_multiseed" {
    h = CoordHandle();
    t1 = attach_task(h, "t1");
    t2 = attach_task(h, "t2", failed=True);
    t3 = attach_task(h, "t3", failed=True);
    t4 = attach_task(h, "t4", failed=True);
    link_depends(t1, t2);
    link_depends(t2, t3);
    link_depends(t1, t4);
    got = cascade_failed_tasks(["t1", "t4"], h);
    assert got == ["t2", "t3", "t4"];
}
