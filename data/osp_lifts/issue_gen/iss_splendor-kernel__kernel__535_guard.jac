"""Guard: splendor-kernel/kernel#535."""

obj ChangeGraph { has subjects: dict[str, Subject] = {}; }
node Subject { has sid: str; }
edge ImpactEdge {}

def load_change_graph(
    subjects: list[str],
    edges: list[tuple[str, str]],
) -> ChangeGraph {
    g = ChangeGraph();
    for sid in subjects {
        if sid not in g.subjects {
            nd = Subject(sid=sid);
            root ++> nd;
            g.subjects[sid] = nd;
        }
    }
    for (src, dst) in edges {
        a = g.subjects.get(src, None);
        b = g.subjects.get(dst, None);
        if a is not None and b is not None { a +>:ImpactEdge:+> b; }
    }
    return g;
}

def direct_dependents(g: ChangeGraph, subject: str) -> list[str] {
    anchor = g.subjects.get(subject, None);
    if anchor is None { return []; }
    out: list[str] = [];
    for dep in [anchor ->:ImpactEdge:->][?:Subject] {
        out.append(dep.sid);
    }
    out.sort();
    return out;
}

def blast_radius(g: ChangeGraph, subject: str) -> list[str] {
    if subject not in g.subjects { return []; }
    claimed: dict[str, bool] = {subject: True};
    snap: list[str] = [subject];
    i = 0;
    while i < len(snap) {
        sid = snap[i];
        i += 1;
        anchor = g.subjects.get(sid, None);
        if anchor is None { continue; }
        for dep in [anchor ->:ImpactEdge:->][?:Subject] {
            if dep.sid not in claimed {
                claimed[dep.sid] = True;
                snap.append(dep.sid);
            }
        }
    }
    ids: list[str] = [];
    for sid in claimed.keys() { ids.append(sid); }
    ids.sort();
    return ids;
}

test "change blast radius includes transitive dependents" {
    g = load_change_graph(
        ["model", "tokenizer", "routenode", "agent"],
        [("model", "tokenizer"), ("model", "routenode"), ("routenode", "agent")],
    );
    assert direct_dependents(g, "model") == ["routenode", "tokenizer"];
    assert blast_radius(g, "model") == ["agent", "model", "routenode", "tokenizer"];
}

test "cyclic dependency graph terminates" {
    g = load_change_graph(
        ["a", "b", "c", "d"],
        [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d")],
    );
    assert blast_radius(g, "a") == ["a", "b", "c", "d"];
}

test "diamond adversarial dependent revisit" {
    g = load_change_graph(
        ["seed", "left", "right", "sink"],
        [("seed", "left"), ("seed", "right"), ("left", "sink"), ("right", "sink")],
    );
    assert blast_radius(g, "seed") == ["left", "right", "seed", "sink"];
}

test "unknown subject tolerant" {
    g = load_change_graph(["solo"], []);
    assert blast_radius(g, "missing") == [];
}
