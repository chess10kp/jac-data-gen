"""Guard: JulianDouma/speckle#65."""

obj BeadsStore { has issues: dict[str, Bead] = {}; }
node Bead { has iid: str; }
edge ParentOf {}

walker SubtreeWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    can step with Bead entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.hits.append(here.iid);
        visit [->:ParentOf:->][?:Bead];
    }
}

def load_beads(
    issues: list[str],
    parent_edges: list[tuple[str, str]],
) -> BeadsStore {
    g = BeadsStore();
    for iid in issues {
        if iid not in g.issues {
            nd = Bead(iid=iid);
            root ++> nd;
            g.issues[iid] = nd;
        }
    }
    for (child, parent) in parent_edges {
        p = g.issues.get(parent, None);
        c = g.issues.get(child, None);
        if p is None or c is None { continue; }
        p +>:ParentOf:+> c;
    }
    return g;
}

def direct_children(g: BeadsStore, parent_id: str) -> list[str] {
    nd = g.issues.get(parent_id, None);
    if nd is None { return []; }
    out: list[str] = [];
    for ch in [nd ->:ParentOf:->][?:Bead] { out.append(ch.iid); }
    return sorted(out);
}

def subtree_ids(g: BeadsStore, root_id: str) -> list[str] {
    start = g.issues.get(root_id, None);
    if start is None { return []; }
    w = start spawn SubtreeWalk(claimed={}, hits=[]);
    return sorted(w.hits);
}

def rollup_stats(
    g: BeadsStore,
    root_id: str,
    statuses: dict[str, str],
) -> dict[str, int | str] {
    ids = subtree_ids(g, root_id);
    if not ids {
        return {
            "children_count": 0,
            "children_closed": 0,
            "progress": 0,
            "status_rollup": "unknown",
        };
    }
    child_only: list[str] = [];
    for iid in ids { if iid != root_id { child_only.append(iid); } }
    closed = 0;
    for iid in child_only { if statuses.get(iid) == "closed" { closed += 1; } }
    total = len(child_only);
    progress = int((closed * 100) / total) if total else 100;
    rollup = "in_progress";
    if progress == 100 { rollup = "done"; }
    elif progress == 0 { rollup = "open"; }
    return {
        "children_count": total,
        "children_closed": closed,
        "progress": progress,
        "status_rollup": rollup,
    };
}

test "hierarchy and rollup" {
    g = load_beads(
        ["epic", "a", "b", "c"],
        [("a", "epic"), ("b", "epic"), ("c", "b")],
    );
    st = {"a": "closed", "b": "open", "c": "closed", "epic": "open"};
    assert direct_children(g, "epic") == ["a", "b"];
    assert subtree_ids(g, "epic") == ["a", "b", "c", "epic"];
    rs = rollup_stats(g, "epic", st);
    assert rs["children_count"] == 3;
    assert rs["progress"] == 66;
}

test "diamond subtree adversarial" {
    g = load_beads(
        ["hub", "left", "right", "leaf"],
        [("leaf", "right"), ("left", "hub"), ("leaf", "left"), ("right", "hub")],
    );
    assert subtree_ids(g, "hub") == ["hub", "leaf", "left", "right"];
}

test "unknown root tolerant" {
    g = load_beads(["solo"], []);
    assert subtree_ids(g, "missing") == [];
    assert rollup_stats(g, "missing", {})["status_rollup"] == "unknown";
}
