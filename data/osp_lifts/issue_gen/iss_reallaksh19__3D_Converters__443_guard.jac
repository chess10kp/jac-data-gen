"""Guard: reallaksh19/3D_Converters#443."""

obj CalcGraph { has calcs: dict[str, Calc] = {}; }
node Calc { has cid: str; }
edge DependsOn {}

def load_calc_graph(
    calcs: list[str],
    depends_edges: list[tuple[str, str]],
) -> CalcGraph {
    g = CalcGraph();
    for cid in calcs {
        if cid not in g.calcs {
            nd = Calc(cid=cid);
            root ++> nd;
            g.calcs[cid] = nd;
        }
    }
    for (prereq, calc) in depends_edges {
        a = g.calcs.get(prereq, None);
        b = g.calcs.get(calc, None);
        if a is not None and b is not None { a +>:DependsOn:+> b; }
    }
    return g;
}

def prerequisites(g: CalcGraph, calc_id: str) -> list[str] {
    if calc_id not in g.calcs { return []; }
    claimed: dict[str, bool] = {calc_id: True};
    snap: list[str] = [calc_id];
    i = 0;
    while i < len(snap) {
        sid = snap[i];
        i += 1;
        anchor = g.calcs.get(sid, None);
        if anchor is None { continue; }
        for p in [anchor <-:DependsOn:<-][?:Calc] {
            if p.cid not in claimed {
                claimed[p.cid] = True;
                snap.append(p.cid);
            }
        }
    }
    ids: list[str] = [];
    for cid in claimed.keys() { ids.append(cid); }
    ids.sort();
    return ids;
}

def ready_calcs(g: CalcGraph, completed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in completed { done[c] = True; }
    ready: list[str] = [];
    for cid in g.calcs.keys() {
        if cid in done { continue; }
        needs = prerequisites(g, cid);
        ok = True;
        for p in needs {
            if p != cid and p not in done { ok = False; }
        }
        if ok { ready.append(cid); }
    }
    ready.sort();
    return ready;
}

test "fit calc prerequisites" {
    g = load_calc_graph(
        ["topology", "operating", "enrichment", "screening", "LOF"],
        [
            ("topology", "screening"),
            ("operating", "screening"),
            ("enrichment", "screening"),
            ("screening", "LOF"),
        ],
    );
    assert prerequisites(g, "LOF") == [
        "LOF", "enrichment", "operating", "screening", "topology",
    ];
    assert ready_calcs(g, ["topology", "operating", "enrichment"]) == ["screening"];
}

test "diamond join readiness" {
    g = load_calc_graph(
        ["base", "left", "right", "join"],
        [("base", "left"), ("base", "right"), ("left", "join"), ("right", "join")],
    );
    assert prerequisites(g, "join") == ["base", "join", "left", "right"];
    assert ready_calcs(g, ["base", "left", "right"]) == ["join"];
}

test "unknown calc tolerant" {
    g = load_calc_graph(["solo"], []);
    assert prerequisites(g, "missing") == [];
}
