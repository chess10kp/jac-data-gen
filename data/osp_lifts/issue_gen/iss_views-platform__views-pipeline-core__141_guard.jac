"""Guard: views-platform/views-pipeline-core#141."""

obj PipelineGraph { has stages: dict[str, Stage] = {}; }
node Stage { has sid: str; }
edge Requires {}

def load_pipeline(
    stages: list[str],
    requires: list[tuple[str, str]],
) -> PipelineGraph {
    g = PipelineGraph();
    for sid in stages {
        if sid not in g.stages {
            nd = Stage(sid=sid);
            root ++> nd;
            g.stages[sid] = nd;
        }
    }
    for (prereq, stage) in requires {
        a = g.stages.get(prereq, None);
        b = g.stages.get(stage, None);
        if a is not None and b is not None { a +>:Requires:+> b; }
    }
    return g;
}

def all_prerequisites(g: PipelineGraph, stage: str) -> list[str] {
    if stage not in g.stages { return []; }
    claimed: dict[str, bool] = {stage: True};
    snap: list[str] = [stage];
    i = 0;
    while i < len(snap) {
        sid = snap[i];
        i += 1;
        anchor = g.stages.get(sid, None);
        if anchor is None { continue; }
        for p in [anchor <-:Requires:<-][?:Stage] {
            if p.sid not in claimed {
                claimed[p.sid] = True;
                snap.append(p.sid);
            }
        }
    }
    ids: list[str] = [];
    for sid in claimed.keys() { ids.append(sid); }
    ids.sort();
    return ids;
}

def runnable_stages(g: PipelineGraph, completed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in completed { done[c] = True; }
    ready: list[str] = [];
    for sid in g.stages.keys() {
        if sid in done { continue; }
        needs = all_prerequisites(g, sid);
        ok = True;
        for p in needs {
            if p != sid and p not in done { ok = False; }
        }
        if ok { ready.append(sid); }
    }
    ready.sort();
    return ready;
}

test "pipeline strategic issue waits on prerequisites" {
    g = load_pipeline(
        ["136", "137", "139", "140", "141"],
        [
            ("136", "141"),
            ("137", "141"),
            ("139", "141"),
            ("140", "141"),
        ],
    );
    assert all_prerequisites(g, "141") == ["136", "137", "139", "140", "141"];
    assert runnable_stages(g, []) == ["136", "137", "139", "140"];
    assert runnable_stages(g, ["136", "137", "139", "140"]) == ["141"];
}

test "unknown stage tolerant" {
    g = load_pipeline(["solo"], []);
    assert all_prerequisites(g, "missing") == [];
}
