"""Guard: imrohitagrawal/narratwin-ai#435."""

obj PhaseGraph { has phases: dict[str, Phase] = {}; }
node Phase { has pid: str; }
edge Requires {}

def load_phase_graph(
    phases: list[str],
    requires_edges: list[tuple[str, str]],
) -> PhaseGraph {
    g = PhaseGraph();
    for pid in phases {
        if pid not in g.phases {
            nd = Phase(pid=pid);
            root ++> nd;
            g.phases[pid] = nd;
        }
    }
    for (prereq, phase) in requires_edges {
        a = g.phases.get(prereq, None);
        b = g.phases.get(phase, None);
        if a is not None and b is not None { a +>:Requires:+> b; }
    }
    return g;
}

def upstream_phases(g: PhaseGraph, phase_id: str) -> list[str] {
    if phase_id not in g.phases { return []; }
    claimed: dict[str, bool] = {phase_id: True};
    snap: list[str] = [phase_id];
    i = 0;
    while i < len(snap) {
        sid = snap[i];
        i += 1;
        anchor = g.phases.get(sid, None);
        if anchor is None { continue; }
        for p in [anchor <-:Requires:<-][?:Phase] {
            if p.pid not in claimed {
                claimed[p.pid] = True;
                snap.append(p.pid);
            }
        }
    }
    ids: list[str] = [];
    for pid in claimed.keys() { ids.append(pid); }
    ids.sort();
    return ids;
}

def ready_phases(g: PhaseGraph, completed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in completed { done[c] = True; }
    ready: list[str] = [];
    for pid in g.phases.keys() {
        if pid in done { continue; }
        needs = upstream_phases(g, pid);
        ok = True;
        for p in needs {
            if p != pid and p not in done { ok = False; }
        }
        if ok { ready.append(pid); }
    }
    ready.sort();
    return ready;
}

test "governance pipeline prerequisites" {
    g = load_phase_graph(
        ["bounds", "parse", "schema", "trust", "auth", "graph", "verdict"],
        [
            ("bounds", "parse"),
            ("parse", "schema"),
            ("schema", "trust"),
            ("trust", "auth"),
            ("auth", "graph"),
            ("graph", "verdict"),
        ],
    );
    assert upstream_phases(g, "verdict") == [
        "auth", "bounds", "graph", "parse", "schema", "trust", "verdict",
    ];
    assert ready_phases(g, []) == ["bounds"];
    assert ready_phases(g, ["bounds", "parse", "schema"]) == ["trust"];
}

test "diamond adversarial order" {
    g = load_phase_graph(
        ["root", "left", "right", "join"],
        [("root", "left"), ("root", "right"), ("left", "join"), ("right", "join")],
    );
    assert upstream_phases(g, "join") == ["join", "left", "right", "root"];
}

test "unknown phase tolerant" {
    g = load_phase_graph(["solo"], []);
    assert upstream_phases(g, "missing") == [];
}
