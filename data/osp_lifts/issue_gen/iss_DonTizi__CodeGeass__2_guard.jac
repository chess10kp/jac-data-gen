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

def has_cycle(store: TaskGraph) -> bool {
    for start in sorted(store.tasks.keys()) {
        state: dict[str, int] = {};
        stack: list[str] = [start];
        while len(stack) > 0 {
            cur = stack[len(stack) - 1];
            nd = store.tasks.get(cur, None);
            if nd is None {
                stack = stack[0 : len(stack) - 1];
                continue;
            }
            st = state.get(cur, 0);
            if st == 0 {
                state[cur] = 1;
                pushed = False;
                for blk in [nd ->:Blocks:->][?:Task] {
                    if state.get(blk.tid, 0) == 1 { return True; }
                    if state.get(blk.tid, 0) == 0 {
                        stack.append(blk.tid);
                        pushed = True;
                    }
                }
                if not pushed {
                    state[cur] = 2;
                    stack = stack[0 : len(stack) - 1];
                }
            } elif st == 1 {
                state[cur] = 2;
                stack = stack[0 : len(stack) - 1];
            } else {
                stack = stack[0 : len(stack) - 1];
            }
        }
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

test "ready frontier" {
    g = load_tasks(["a", "b", "c"], [("a", "b"), ("b", "c")], done=["a"]);
    assert has_cycle(g) == False;
    assert ready_tasks(g) == ["b"];
}

test "cycle detected" {
    cyc = load_tasks(["x", "y"], [("x", "y"), ("y", "x")]);
    assert has_cycle(cyc) == True;
}
