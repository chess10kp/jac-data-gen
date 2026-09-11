"""CentralInfraCore/cic-factory-core#45 — Factory task dependency readiness walk."""

node Task { has tid: str; }
edge Blocks {}

obj FactoryPlan {
    has tasks: dict[str, Task] = {};
}

def load_plan(
    tasks: list[str],
    edges: list[tuple[str, str]],
) -> FactoryPlan {
    plan = FactoryPlan();
    for tid in tasks {
        if tid not in plan.tasks {
            nd = Task(tid=tid);
            root ++> nd;
            plan.tasks[tid] = nd;
        }
    }
    for (blocker, blocked) in edges {
        a = plan.tasks.get(blocker, None);
        b = plan.tasks.get(blocked, None);
        if a is not None and b is not None { a +>:Blocks:+> b; }
    }
    return plan;
}

def blocked_by(plan: FactoryPlan, task_id: str) -> list[str] {
    anchor = plan.tasks.get(task_id, None);
    if anchor is None { return []; }
    claimed: dict[str, bool] = {};
    snap: list[str] = [];
    for blk in [anchor <-:Blocks:<-][?:Task] {
        if blk.tid not in claimed {
            claimed[blk.tid] = True;
            snap.append(blk.tid);
        }
    }
    i = 0;
    while i < len(snap) {
        tid = snap[i];
        i += 1;
        nd = plan.tasks.get(tid, None);
        if nd is None { continue; }
        for blk in [nd <-:Blocks:<-][?:Task] {
            if blk.tid not in claimed {
                claimed[blk.tid] = True;
                snap.append(blk.tid);
            }
        }
    }
    out: list[str] = [];
    for tid in claimed.keys() { out.append(tid); }
    return sorted(out);
}

def ready_tasks(plan: FactoryPlan, completed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in completed { done[c] = True; }
    ready: list[str] = [];
    for tid in sorted(plan.tasks.keys()) {
        if tid in done { continue; }
        needs = blocked_by(plan, tid);
        ok = True;
        for dep in needs {
            if dep not in done { ok = False; }
        }
        if ok { ready.append(tid); }
    }
    return ready;
}

def wave_count(plan: FactoryPlan) -> int {
    done: list[str] = [];
    waves = 0;
    while len(done) < len(plan.tasks) {
        nxt = ready_tasks(plan, done);
        if not nxt { break; }
        waves += 1;
        for t in nxt { done.append(t); }
    }
    return waves;
}
