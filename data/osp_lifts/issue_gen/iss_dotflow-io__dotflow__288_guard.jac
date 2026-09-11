"""dotflow-io/dotflow#288 — DAG executor with topological levels and cascade removal."""

node Step {
    has sid: str;
    has active: bool = True;
}

edge DependsOn {}

class CycleError(Exception) {}

obj DagExecutor {
    has steps: dict[str, Step] = {};
}

walker DepCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with Step entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid != self.anchor {
            self.found.append(here.sid);
        }
        visit [<-:DependsOn:<-][?:Step];
    }
}

def load_dag(
    step_names: list[str],
    depends_edges: list[tuple[str, str]],
) -> DagExecutor {
    dag = DagExecutor();
    for step in step_names {
        nd = Step(sid=step);
        root ++> nd;
        dag.steps[step] = nd;
    }
    for (upstream, downstream) in depends_edges {
        u = dag.steps.get(upstream, None);
        d = dag.steps.get(downstream, None);
        if u is not None and d is not None { d +>:DependsOn:+> u; }
    }
    return dag;
}

def topological_levels(store: DagExecutor) -> list[list[str]] {
    indegree: dict[str, int] = {};
    rev: dict[str, list[str]] = {};
    for sid in store.steps { indegree[sid] = 0; rev[sid] = []; }
    for sid in store.steps {
        nd = store.steps[sid];
        indegree[sid] = len([nd ->:DependsOn:->][?:Step]);
        for up in [nd ->:DependsOn:->][?:Step] {
            rev[up.sid].append(sid);
        }
    }
    levels: list[list[str]] = [];
    visited: dict[str, bool] = {};
    pending = len(store.steps);
    while pending > 0 {
        lvl = sorted([sid for sid in store.steps if sid not in visited and indegree[sid] == 0]);
        if len(lvl) == 0 {
            raise CycleError("cycle");
        }
        levels.append(lvl);
        for node in lvl {
            visited[node] = True;
            pending -= 1;
            for other in rev.get(node, []) {
                indegree[other] -= 1;
            }
        }
    }
    return levels;
}

def remove_step(store: DagExecutor, step: str) -> list[str] {
    nd = store.steps.get(step, None);
    if nd is None { return []; }
    w = nd spawn DepCollect(claimed={}, anchor=step);
    removed = [step] + w.found;
    for sid in removed {
        s = store.steps.get(sid, None);
        if s is not None { s.active = False; }
    }
    return sorted(removed);
}

def active_steps(store: DagExecutor) -> list[str] {
    out: list[str] = [];
    for sid in store.steps {
        if store.steps[sid].active { out.append(sid); }
    }
    return sorted(out);
}

test "dag topological levels" {
    dag = load_dag(
        ["extract", "transform_a", "transform_b", "load"],
        [
            ("extract", "transform_a"),
            ("extract", "transform_b"),
            ("transform_a", "load"),
            ("transform_b", "load"),
        ],
    );
    levels = topological_levels(dag);
    assert levels[0] == ["extract"];
    assert sorted(levels[1]) == ["transform_a", "transform_b"];
    assert levels[2] == ["load"];
    assert remove_step(dag, "extract") == ["extract", "load", "transform_a", "transform_b"];
    assert active_steps(dag) == [];
}

test "cycle raises" {
    dag2 = load_dag(["a", "b"], [("a", "b"), ("b", "a")]);
    caught = False;
    try {
        topological_levels(dag2);
    } except CycleError {
        caught = True;
    }
    assert caught is True;
}
