"""snissn/music#1 — SongDNA issue dependency graph for execution scheduling."""

obj IssueGraph {
    has issues: dict[str, Issue] = {};
}

node Issue {
    has iid: str;
}

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
