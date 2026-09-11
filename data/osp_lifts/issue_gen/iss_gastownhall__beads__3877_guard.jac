"""gastownhall/beads#3877 — recursive blocks closure for ready-work reach."""

node Issue {
    has iid: str;
}

edge Blocks {}

walker ReachBlocksWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Issue entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.order.append(here.iid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: Issue) -> list[Issue] {
    kids: list[Issue] = [];
    for ch in [nd ->:Blocks:->][?:Issue] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.iid); }
    names = sorted(names);
    ordered: list[Issue] = [];
    for nm in names { for ch in kids { if ch.iid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_issue(iid: str, store: dict) -> Issue | None {
    nmap = store["nodes"] as dict[str, Issue];
    if iid in nmap { return nmap[iid]; }
    return None;
}

def fresh_issue_store() -> dict { return {"issues": {}, "blocks": {}, "rev": {}, "nodes": {}}; }

def register_issue(issue_id: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_issue_store(); }
    (s["issues"] as dict[str, bool])[issue_id] = True;
    outs = s["blocks"] as dict[str, list[str]];
    if issue_id not in outs { outs[issue_id] = []; }
    rev = s["rev"] as dict[str, list[str]];
    if issue_id not in rev { rev[issue_id] = []; }
    nd = Issue(iid=issue_id);
    root ++> nd;
    (s["nodes"] as dict[str, Issue])[issue_id] = nd;
    return s;
}

def add_blocks_edge(blocker_id: str, blocked_id: str, store: dict) {
    imap = store["issues"] as dict[str, bool];
    if blocker_id not in imap or blocked_id not in imap { raise KeyError("unknown issue id"); }
    if blocker_id == blocked_id { return; }
    src_nd = _find_issue(blocker_id, store);
    tgt_nd = _find_issue(blocked_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:Blocks:->][?:Issue] { if ex.iid == blocked_id { seen = True; } }
        if not seen { src_nd +>:Blocks:+> tgt_nd; }
    }
    outs = store["blocks"] as dict[str, list[str]];
    if blocker_id not in outs { outs[blocker_id] = []; }
    if blocked_id not in outs[blocker_id] { outs[blocker_id].append(blocked_id); outs[blocker_id] = sorted(outs[blocker_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if blocked_id not in revs { revs[blocked_id] = []; }
    if blocker_id not in revs[blocked_id] { revs[blocked_id].append(blocker_id); revs[blocked_id] = sorted(revs[blocked_id]); }
}

def direct_blocked(blocker_id: str, store: dict) -> list[str] {
    if blocker_id not in (store["issues"] as dict) { raise KeyError(blocker_id); }
    return list((store["blocks"] as dict[str, list[str]]).get(blocker_id, []));
}

def direct_blockers(blocked_id: str, store: dict) -> list[str] {
    if blocked_id not in (store["issues"] as dict) { raise KeyError(blocked_id); }
    return list((store["rev"] as dict[str, list[str]]).get(blocked_id, []));
}

def transitive_blocked(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["issues"] as dict) { raise KeyError(start_id); }
    start_nd = _find_issue(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachBlocksWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for iid in w.order { if iid != start_id { reach.append(iid); } }
    return reach;
}

def ready_reach_report(start_id: str, store: dict) -> dict {
    reach = transitive_blocked(start_id, store);
    direct = direct_blocked(start_id, store);
    return {"direct": direct, "reach": reach, "reach_count": len(reach)};
}

test "diamond revisit keeps single shared target" {
    s = fresh_issue_store();
    register_issue("epic", s);
    register_issue("child_a", s);
    register_issue("child_b", s);
    register_issue("leaf", s);
    add_blocks_edge("epic", "child_a", s);
    add_blocks_edge("epic", "child_b", s);
    add_blocks_edge("child_a", "leaf", s);
    add_blocks_edge("child_b", "leaf", s);
    got = transitive_blocked("epic", s);
    assert got == ["child_a", "leaf", "child_b"];
    l_count = 0;
    for iid in got { if iid == "leaf" { l_count += 1; } }
    assert l_count == 1;
}

test "adversarial blocks insertion order is stable" {
    s1 = fresh_issue_store();
    register_issue("epic", s1);
    register_issue("child_a", s1);
    register_issue("child_b", s1);
    register_issue("leaf", s1);
    add_blocks_edge("epic", "child_b", s1);
    add_blocks_edge("child_b", "leaf", s1);
    add_blocks_edge("epic", "child_a", s1);
    add_blocks_edge("child_a", "leaf", s1);
    s2 = fresh_issue_store();
    register_issue("epic", s2);
    register_issue("child_a", s2);
    register_issue("child_b", s2);
    register_issue("leaf", s2);
    add_blocks_edge("epic", "child_a", s2);
    add_blocks_edge("child_a", "leaf", s2);
    add_blocks_edge("epic", "child_b", s2);
    add_blocks_edge("child_b", "leaf", s2);
    assert transitive_blocked("epic", s1) == transitive_blocked("epic", s2);
}

test "unknown issue ids raise KeyError" {
    s = fresh_issue_store();
    register_issue("epic", s);
    caught = False;
    try { direct_blocked("missing", s); } except KeyError { caught = True; }
    assert caught;
    caught2 = False;
    try { add_blocks_edge("epic", "missing", s); } except KeyError { caught2 = True; }
    assert caught2;
}

test "duplicate blocks edge does not inflate reach" {
    s = fresh_issue_store();
    register_issue("epic", s);
    register_issue("child_a", s);
    add_blocks_edge("epic", "child_a", s);
    add_blocks_edge("epic", "child_a", s);
    assert direct_blocked("epic", s) == ["child_a"];
    rep = ready_reach_report("epic", s);
    assert rep["reach_count"] == 1;
}

test "ready reach report binds direct and transitive facts" {
    s = fresh_issue_store();
    register_issue("epic", s);
    register_issue("child_a", s);
    add_blocks_edge("epic", "child_a", s);
    rep = ready_reach_report("epic", s);
    assert rep["direct"] == ["child_a"];
    assert rep["reach"] == ["child_a"];
    assert rep["reach_count"] == 1;
    assert direct_blockers("child_a", s) == ["epic"];
}
