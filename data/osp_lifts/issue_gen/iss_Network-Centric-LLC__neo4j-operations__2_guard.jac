"""Guard: Network-Centric-LLC/neo4j-operations#2."""

node IssueNode { has iid: str; }
edge BlockedBy {}

obj IssueGraph {
    has issues: dict[str, IssueNode] = {};
    has done: dict[str, bool] = {};
}

walker BlockerWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with IssueNode entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.reached.append(here.iid);
        visit [<-:BlockedBy:<-][?:IssueNode];
    }
}

def load_issue_graph(
    issues: list[str],
    deps: list[tuple[str, str]],
    done: list[str],
) -> IssueGraph {
    g = IssueGraph();
    for iid in issues {
        nd = IssueNode(iid=iid);
        root ++> nd;
        g.issues[iid] = nd;
    }
    for (blocker, issue) in deps {
        blk = g.issues.get(blocker, None);
        tgt = g.issues.get(issue, None);
        if blk is not None and tgt is not None { blk +>:BlockedBy:+> tgt; }
    }
    for d in done { g.done[d] = True; }
    return g;
}

def ready_issues(g: IssueGraph) -> list[str] {
    ready: list[str] = [];
    for (iid, nd) in g.issues.items() {
        if g.done.get(iid, False) { continue; }
        pending = False;
        for blk in [nd <-:BlockedBy:<-][?:IssueNode] {
            if not g.done.get(blk.iid, False) { pending = True; }
        }
        if not pending { ready.append(iid); }
    }
    return sorted(ready);
}

def blocked_closure(g: IssueGraph, issue_id: str) -> list[str] {
    nd = g.issues.get(issue_id, None);
    if nd is None { return []; }
    w = nd spawn BlockerWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def mark_resolved(g: IssueGraph, issue_id: str) {
    if issue_id in g.issues { g.done[issue_id] = True; }
}

test "cycle1 readiness progression" {
    g = load_issue_graph(
        ["epic", "pkg", "driver", "skill"],
        [
            ("epic", "pkg"),
            ("pkg", "driver"),
            ("driver", "skill"),
        ],
        ["epic"],
    );
    assert ready_issues(g) == ["pkg"];
    assert blocked_closure(g, "skill") == ["driver", "epic", "pkg", "skill"];
    mark_resolved(g, "pkg");
    assert ready_issues(g) == ["driver"];
}

test "diamond blocker closure" {
    g = load_issue_graph(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "leaf"),
            ("right", "leaf"),
        ],
        [],
    );
    assert blocked_closure(g, "leaf") == ["hub", "leaf", "left", "right"];
}
