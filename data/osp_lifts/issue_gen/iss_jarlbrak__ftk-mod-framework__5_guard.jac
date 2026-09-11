"""Guard: jarlbrak/ftk-mod-framework#5."""

obj SpecGraph { has specs: dict[str, Spec] = {}; }
node Spec { has sid: str; }
edge Blocks {}

def load_spec_graph(
    specs: list[str],
    edges: list[tuple[str, str]],
) -> SpecGraph {
    g = SpecGraph();
    for sid in specs {
        if sid not in g.specs {
            nd = Spec(sid=sid);
            root ++> nd;
            g.specs[sid] = nd;
        }
    }
    for (blocker, blocked) in edges {
        a = g.specs.get(blocker, None);
        b = g.specs.get(blocked, None);
        if a is not None and b is not None { a +>:Blocks:+> b; }
    }
    return g;
}

def prerequisites(g: SpecGraph, spec_id: str) -> list[str] {
    if spec_id not in g.specs { return []; }
    claimed: dict[str, bool] = {spec_id: True};
    snap: list[str] = [spec_id];
    i = 0;
    while i < len(snap) {
        sid = snap[i];
        i += 1;
        anchor = g.specs.get(sid, None);
        if anchor is None { continue; }
        for p in [anchor <-:Blocks:<-][?:Spec] {
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

def ready_specs(g: SpecGraph, completed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in completed { done[c] = True; }
    ready: list[str] = [];
    for sid in g.specs.keys() {
        if sid in done { continue; }
        needs = prerequisites(g, sid);
        ok = True;
        for p in needs {
            if p != sid and p not in done { ok = False; }
        }
        if ok { ready.append(sid); }
    }
    ready.sort();
    return ready;
}

test "campaign spec prerequisites and readiness" {
    g = load_spec_graph(
        ["P1", "P2", "P3", "P5", "POC"],
        [("P1", "P2"), ("P1", "P3"), ("P3", "P2"), ("P2", "POC"), ("P5", "POC")],
    );
    assert prerequisites(g, "POC") == ["P1", "P2", "P3", "P5", "POC"];
    assert ready_specs(g, []) == ["P1", "P5"];
    assert ready_specs(g, ["P1", "P5"]) == ["P3"];
    assert ready_specs(g, ["P1", "P3", "P5"]) == ["P2"];
}

test "unknown spec tolerant" {
    g = load_spec_graph(["solo"], []);
    assert prerequisites(g, "missing") == [];
}
