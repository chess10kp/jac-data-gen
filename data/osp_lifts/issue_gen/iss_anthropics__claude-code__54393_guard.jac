# Issue anthropics/claude-code#54393
# Multi-agent coordination post-mortem: dependency-gated task cascade.
# Python had hand-rolled adjacency dicts + recursive cascade sweeps;
# lifted to idiomatic OSP: Task nodes, NEEDS edges, cascade walker.

node Task {
    has tid: str;
    has kind: str;          # "build" | "audit" | "data_integrity"
    has gate: bool = False; # completed?
    has touched: bool = False;
}

edge NEEDS {}   # a NEEDS b : a cannot run before b
edge OWNED {}   # coordinator owns workers

# Parse "id,kind,gate;id,kind,gate;..." spec into the graph.
def build_graph(spec: str) -> Task | None {
    root_node: Task | None = None;
    idx: dict[str, Task] = {};
    parts: list[str] = spec.split(";");
    for s in parts {
        f: list[str] = s.split(",");
        t = Task(tid=f[0], kind=f[1], gate=(f[2] == "1"));
        idx[f[0]] = t;
        if root_node is None {
            root_node = t;
        }
    }
    for s in parts {
        f: list[str] = s.split(",");
        a = idx[f[0]];
        for d in f[3:] {
            b = idx[d];
            a +>:NEEDS:+> b;
        }
    }
    return root_node;
}

# Public API: unresolved prerequisites of a task (sorted, order-free shape).
def blockers(hub: Task, tid: str) -> list[str] {
    target: Task | None = None;
    for t in [hub ->:NEEDS:*->][?:Task] {
        if t.tid == tid { target = t; }
    }
    if target is None {
        return [];   # unknown-id tolerance: no blockers, not an error
    }
    ids: list[str] = [];
    for b in [target ->:NEEDS:*->][?:Task] {
        if not b.gate {
            ids.append(b.tid);
        }
    }
    return sorted(ids);
}

walker Cascade {
    has claimed: dict[str, bool] = {};
    has ran: list[str] = [];

    can step with Task entry {
        if here.tid in self.claimed {
            skip;   # cycle policy: claim-map + skip, never disengage
        }
        self.claimed[here.tid] = True;
        here.touched = True;
        if here.kind == "data_integrity" and not here.gate {
            here.gate = True;   # integrity gates must land before builds
        }
        self.ran.append(here.tid);
        kids: list[Task] = [here <-:NEEDS:-][?:Task];
        visit :0: kids else { disengage; }
    }
}

def run_cascade(hub: Task) -> list[str] {
    w = hub spawn Cascade(claimed={});
    return sorted(w.ran);
}

with entry {
    hub = build_graph("pm,build,0;integ,data_integrity,0;backtest,build,0;pm.integ;backtest.pm,integ");
    root ++> hub;
    wk = hub spawn Cascade(claimed={});
    print(wk.ran);
}

test "diamond revisit closure" {
    hub = build_graph("a,build,0;b,build,0;c,build,0;d,build,0;a.b,a.c;b.d,c.d");
    ran = run_cascade(hub);
    assert ran == ["a", "b", "c", "d"];
}

test "integrity gate lands before build" {
    hub = build_graph("pm,build,0;integ,data_integrity,0;pm.integ");
    assert blockers(hub, "pm") == ["integ"];
    run_cascade(hub);
    for t in [hub ->:NEEDS:*->][?:Task] {
        if t.kind == "data_integrity" {
            assert t.gate;
        }
    }
}

test "unknown id tolerated" {
    hub = build_graph("a,build,0");
    assert blockers(hub, "nope") == [];
}

test "blocked by ungated prerequisites" {
    hub = build_graph("pm,build,0;i1,data_integrity,1;i2,data_integrity,0;pm.i1,pm.i2");
    assert blockers(hub, "pm") == ["i2"];
}

test "empty graph hub only" {
    hub = build_graph("solo,audit,1");
    assert run_cascade(hub) == ["solo"];
}
