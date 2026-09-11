"""Guard: snissn/music#1."""

obj IssueGraph { has issues: dict[str, Issue] = {}; }
node Issue { has iid: str; }
edge Blocks {}

def load_issue_graph(
    issues: list[str],
    blocks: list[tuple[str, str]],
) -> IssueGraph {
    g = IssueGraph();
    for iid in issues {
        if iid not in g.issues {
            nd = Issue(iid=iid);
            root ++> nd;
            g.issues[iid] = nd;
        }
    }
    for (blocker, blocked) in blocks {
        a = g.issues.get(blocker, None);
        b = g.issues.get(blocked, None);
        if a is not None and b is not None { a +>:Blocks:+> b; }
    }
    return g;
}

def critical_path(g: IssueGraph, target: str) -> list[str] {
    if target not in g.issues { return []; }
    claimed: dict[str, bool] = {target: True};
    snap: list[str] = [target];
    i = 0;
    while i < len(snap) {
        sid = snap[i];
        i += 1;
        anchor = g.issues.get(sid, None);
        if anchor is None { continue; }
        for p in [anchor <-:Blocks:<-][?:Issue] {
            if p.iid not in claimed {
                claimed[p.iid] = True;
                snap.append(p.iid);
            }
        }
    }
    ids: list[str] = [];
    for iid in claimed.keys() { ids.append(iid); }
    ids.sort();
    return ids;
}

def unblocked(g: IssueGraph, done: list[str]) -> list[str] {
    finished: dict[str, bool] = {};
    for d in done { finished[d] = True; }
    ready: list[str] = [];
    for iid in g.issues.keys() {
        if iid in finished { continue; }
        blockers = critical_path(g, iid);
        ok = True;
        for b in blockers {
            if b != iid and b not in finished { ok = False; }
        }
        if ok { ready.append(iid); }
    }
    ready.sort();
    return ready;
}

test "songdna critical path to final gate" {
    g = load_issue_graph(
        ["2", "3", "4", "5", "6", "7", "8"],
        [
            ("2", "3"), ("2", "5"), ("2", "6"),
            ("3", "4"), ("3", "7"), ("4", "6"), ("4", "7"), ("4", "8"),
            ("5", "8"), ("6", "8"), ("7", "8"),
        ],
    );
    assert critical_path(g, "8") == ["2", "3", "4", "5", "6", "7", "8"];
    assert unblocked(g, []) == ["2"];
    assert unblocked(g, ["2"]) == ["3", "5"];
    assert unblocked(g, ["2", "3", "4", "5", "6", "7"]) == ["8"];
}

test "unknown issue tolerant" {
    g = load_issue_graph(["solo"], []);
    assert critical_path(g, "missing") == [];
}
