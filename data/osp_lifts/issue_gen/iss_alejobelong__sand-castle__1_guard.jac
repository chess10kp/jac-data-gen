"""alejobelong/sand-castle#1 — sandcastle-synth slice DAG scheduler and lineage reach."""

node Slice {
    has sid: str;
}

edge DependsOn {}

class CycleError(Exception) {}

obj PlanHandle {
    has slices: dict[str, Slice] = {};
    has max_concurrency: int = 1;
}

walker DownstreamReach {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Slice entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid != self.origin {
            self.found.append(here.sid);
        }
        visit [<-:DependsOn:<-][?:Slice];
    }
}

walker UpstreamClosure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with Slice entry {
        if here.sid == self.anchor {
            visit [here ->:DependsOn:->][?:Slice];
            skip;
        }
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.found.append(here.sid);
        visit [->:DependsOn:->][?:Slice];
    }
}

def load_plan(
    slice_ids: list[str],
    depends_edges: list[tuple[str, str]],
    *,
    max_concurrency: int = 1,
) -> PlanHandle {
    plan = PlanHandle(max_concurrency=max(1, max_concurrency));
    for sid in slice_ids {
        nd = Slice(sid=sid);
        root ++> nd;
        plan.slices[sid] = nd;
    }
    for (upstream, downstream) in depends_edges {
        if upstream not in plan.slices or downstream not in plan.slices {
            raise KeyError("unknown slice");
        }
        dn = plan.slices[downstream];
        up = plan.slices[upstream];
        dn +>:DependsOn:+> up;
    }
    return plan;
}

def topological_levels(plan: PlanHandle) -> list[list[str]] {
    indeg: dict[str, int] = {};
    for sid in plan.slices {
        nd = plan.slices[sid];
        indeg[sid] = len([nd ->:DependsOn:->][?:Slice]);
    }
    levels: list[list[str]] = [];
    visited: dict[str, bool] = {};
    ready = sorted([sid for sid in plan.slices if indeg[sid] == 0]);
    while ready {
        layer = ready;
        levels.append(layer);
        nxt: list[str] = [];
        for sid in layer {
            visited[sid] = True;
            cur = plan.slices[sid];
            for dn in [cur <-:DependsOn:<-][?:Slice] {
                indeg[dn.sid] -= 1;
                if indeg[dn.sid] == 0 and dn.sid not in visited {
                    nxt.append(dn.sid);
                }
            }
        }
        ready = sorted(nxt);
    }
    if len(visited) != len(plan.slices) {
        raise CycleError("cycle in slice dependencies");
    }
    return levels;
}

def downstream_reach(plan: PlanHandle, `root: str) -> list[str] {
    if `root not in plan.slices { return []; }
    nd = plan.slices[`root];
    w = nd spawn DownstreamReach(claimed={}, found=[], origin=`root);
    return sorted(w.found);
}

def upstream_closure(plan: PlanHandle, `root: str) -> list[str] {
    if `root not in plan.slices { return []; }
    nd = plan.slices[`root];
    w = nd spawn UpstreamClosure(claimed={}, found=[], anchor=`root);
    return sorted(w.found);
}

def ready_slices(plan: PlanHandle, completed: list[str] | None = None) -> list[str] {
    done: dict[str, bool] = {};
    for sid in (completed or []) { done[sid] = True; }
    ready: list[str] = [];
    keys: list[str] = [];
    for sid in plan.slices { keys.append(sid); }
    for sid in sorted(keys) {
        if sid in done { continue; }
        nd = plan.slices[sid];
        ok = True;
        for up in [nd ->:DependsOn:->][?:Slice] {
            if up.sid not in done { ok = False; }
        }
        if ok { ready.append(sid); }
    }
    return ready;
}

def schedule_batches(plan: PlanHandle, completed: list[str] | None = None) -> list[list[str]] {
    batches: list[list[str]] = [];
    done: list[str] = [];
    for sid in (completed or []) { done.append(sid); }
    while True {
        ready = ready_slices(plan, done);
        if len(ready) == 0 { break; }
        batch = ready[:plan.max_concurrency];
        batches.append(batch);
        for sid in batch { done.append(sid); }
    }
    return batches;
}

test "diamond revisit downstream and upstream" {
    plan = load_plan(
        ["hub", "left", "right", "sink"],
        [("left", "sink"), ("right", "sink"), ("hub", "right"), ("hub", "left")],
    );
    assert downstream_reach(plan, "hub") == ["left", "right", "sink"];;
    assert upstream_closure(plan, "sink") == ["hub", "left", "right"];;
    assert topological_levels(plan) == [["hub"], ["left", "right"], ["sink"]];;
}

test "unknown id tolerance and bad edges" {
    plan = load_plan(["solo"], []);
    assert downstream_reach(plan, "missing") == [];;
    assert upstream_closure(plan, "missing") == [];;
    assert ready_slices(plan, ["missing"]) == ["solo"];;
    try {
        load_plan(["a"], [("a", "b")]);
        assert False, "expected KeyError for unknown downstream";;
    } except KeyError {
        assert True;;
    }
    try {
        load_plan(["a", "b"], [("ghost", "a")]);
        assert False, "expected KeyError for unknown upstream";;
    } except KeyError {
        assert True;;
    }
}

test "cycle detection in topological_levels" {
    plan = load_plan(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    try {
        topological_levels(plan);
        assert False, "expected CycleError";;
    } except CycleError {
        assert True;;
    }
}

test "schedule batches concurrency and partial completion" {
    plan = load_plan(
        ["a", "b", "c", "d"],
        [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
        max_concurrency=2,
    );
    assert schedule_batches(plan, []) == [["a"], ["b", "c"], ["d"]];;
    assert schedule_batches(plan, ["a"]) == [["b", "c"], ["d"]];;
    assert ready_slices(plan, ["a", "b"]) == ["c"];;
    plan2 = load_plan(["a", "b", "c"], [("a", "c")], max_concurrency=2);
    assert schedule_batches(plan2, []) == [["a", "b"], ["c"]];;
}

test "fan-in gate and disconnected topo layer" {
    plan = load_plan(
        ["a", "b", "c", "d"],
        [("a", "c"), ("b", "c"), ("c", "d")],
    );
    assert ready_slices(plan, ["a"]) == ["b"];;
    assert ready_slices(plan, ["a", "b"]) == ["c"];;
    assert ready_slices(plan, ["a", "b", "c"]) == ["d"];;
    forest = load_plan(["p", "q", "r"], [("p", "q")], max_concurrency=2);
    assert topological_levels(forest) == [["p", "r"], ["q"]];;
    assert schedule_batches(forest, []) == [["p", "r"], ["q"]];;
}

test "empty and solo isolated slices" {
    empty = load_plan([], []);
    assert topological_levels(empty) == [];;
    assert ready_slices(empty) == [];;
    assert schedule_batches(empty) == [];;
    solo = load_plan(["only"], []);
    assert downstream_reach(solo, "only") == [];;
    assert upstream_closure(solo, "only") == [];;
    assert ready_slices(solo) == ["only"];;
    assert schedule_batches(solo) == [["only"]];;
    assert topological_levels(solo) == [["only"]];;
}
