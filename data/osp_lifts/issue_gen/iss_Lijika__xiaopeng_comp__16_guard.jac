# iss_Lijika__xiaopeng_comp__16.jac
# Canonical spec Lijika/xiaopeng_comp#16 - Consistency Review Workbench
# Workbench owns Apps, Apps hold Evidence, Evidence Ref Evidence

node Workbench { has wid: str; }
node App { has aid: str; }
node Ev { has eid: str; }

edge Owns {}
edge Holds {}
edge Ref {}

walker ReachEv {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can start with App entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        print(here.aid);
        for nxt in [here ->:Holds:->][?:Ev] {
            visit [nxt];
        }
    }
    can traverse with Ev entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.found.append(here.eid);
        print(here.eid);
        for nxt in [here ->:Ref:->][?:Ev] {
            visit [nxt];
        }
        visit [here ->:Ref:->][?:Ev] else { }
    }
}

walker LineageEv {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can traverse with Ev entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.found.append(here.eid);
        print(here.eid);
        for nxt in [here ->:Ref:->][?:Ev] {
            visit [nxt];
        }
        visit [here ->:Ref:->][?:Ev] else { }
    }
}

def get_app(graph_root: Workbench, aid: str) -> App | None {
    # lookup App by aid under Workbench
    for cand in [graph_root ->:Owns:->][?:App] {
        if cand.aid == aid { return cand; }
    }
    return None;
}

def get_ev(graph_root: Workbench, eid: str) -> Ev | None {
    for a in [graph_root ->:Owns:->][?:App] {
        for e in [a ->:Holds:->][?:Ev] {
            if e.eid == eid { return e; }
        }
        for e in [a ->:Holds:->][?:Ev] {
            for r in [e ->:Ref:->][?:Ev] {
                if r.eid == eid { return r; }
            }
        }
    }
    # fallback scan via walker-style linear scan of Holds closure
    found: list[Ev] = [];
    for a2 in [graph_root ->:Owns:->][?:App] {
        for e2 in [a2 ->:Holds:->][?:Ev] {
            found.append(e2);
        }
    }
    for f in found {
        if f.eid == eid { return f; }
    }
    return None;
}

def wb_create(wid: str) -> Workbench {
    wb: Workbench = Workbench(wid=wid);
    return wb;
}

def app_add(graph_root: Workbench, aid: str) -> App {
    existed: App | None = get_app(graph_root, aid);
    if existed is not None { return existed; }
    nd: App = App(aid=aid);
    graph_root +>:Owns:+> nd;
    return nd;
}

def ev_add(graph_root: Workbench, aid: str, eid: str) -> Ev | None {
    app: App | None = get_app(graph_root, aid);
    if app is None { return None; }
    nd: Ev = Ev(eid=eid);
    app +>:Holds:+> nd;
    return nd;
}

def ref_add(graph_root: Workbench, src_eid: str, dst_eid: str) -> bool {
    src: Ev | None = get_ev(graph_root, src_eid);
    dst: Ev | None = get_ev(graph_root, dst_eid);
    if src is None { return False; }
    if dst is None { return False; }
    src +>:Ref:+> dst;
    return True;
}

def collect_reachable(graph_root: Workbench, aid: str) -> list[str] {
    app: App | None = get_app(graph_root, aid);
    if app is None { return []; }
    w: ReachEv = app spawn ReachEv(claimed={}, found=[]);
    res: list[str] = [];
    for x in w.found { res.append(x); }
    return sorted(res);
}

def collect_lineage(graph_root: Workbench, eid: str) -> list[str] {
    ev: Ev | None = get_ev(graph_root, eid);
    if ev is None { return []; }
    w: LineageEv = ev spawn LineageEv(claimed={}, found=[]);
    res: list[str] = [];
    for x in w.found { res.append(x); }
    return sorted(res);
}

with entry {
    wb: Workbench = Workbench(wid="demo");
    root ++> wb;
    a: App = app_add(wb, "demo_app");
    e1: Ev | None = ev_add(wb, "demo_app", "demo_ev");
    w: ReachEv = a spawn ReachEv(claimed={}, found=[]);
    print(w.found);
}

test "reach_diamond_no_duplicate" {
    wb: Workbench = wb_create("w1");
    root ++> wb;
    app_add(wb, "app");
    ev_add(wb, "app", "a");
    ev_add(wb, "app", "b");
    ev_add(wb, "app", "c");
    ev_add(wb, "app", "d");
    # app holds a ; a refs b,c ; b refs d ; c refs d  (diamond, adversarial insert order)
    assert(ref_add(wb, "a", "b"));
    assert(ref_add(wb, "a", "c"));
    assert(ref_add(wb, "b", "d"));
    assert(ref_add(wb, "c", "d"));
    r: list[str] = collect_reachable(wb, "app");
    # reachable from app via Holds direct + transitive Ref from a
    # Holds gives a,b,c,d directly, but lineage from a also covers b,c,d; deduped sorted
    assert(r == ["a", "b", "c", "d"]);
}

test "reach_no_duplicate_on_shared_ref" {
    wb: Workbench = wb_create("w2");
    root ++> wb;
    app_add(wb, "app");
    app_add(wb, "app_dup");
    # Need shared evidence nodes held by both apps to test shared-ref dedup
    # Create evidences under app then also hold same nodes from app_dup via extra Holds
    ex: Ev | None = ev_add(wb, "app", "ex");
    ey: Ev | None = ev_add(wb, "app", "ey");
    ez: Ev | None = ev_add(wb, "app", "ez");
    app_dup: App | None = get_app(wb, "app_dup");
    if app_dup is not None and ex is not None {
        app_dup +>:Holds:+> ex;
    }
    if app_dup is not None and ey is not None {
        app_dup +>:Holds:+> ey;
    }
    if app_dup is not None and ez is not None {
        app_dup +>:Holds:+> ez;
    }
    # relate ex->ey->ez chain to also test path reach
    assert(ref_add(wb, "ex", "ey"));
    r1: list[str] = collect_reachable(wb, "app");
    r2: list[str] = collect_reachable(wb, "app_dup");
    assert(r1 == ["ex", "ey", "ez"]);
    assert(r2 == ["ex", "ey", "ez"]);
}

test "unknown_id_tolerance" {
    wb: Workbench = wb_create("w3");
    root ++> wb;
    app_add(wb, "app");
    ev_add(wb, "app", "ex");
    assert(collect_reachable(wb, "no_such_app") == []);
    assert(collect_lineage(wb, "no_such_ev") == []);
    assert(ref_add(wb, "ex", "ghost") == False);
    assert(ref_add(wb, "ghost", "ex") == False);
    # existing still intact
    assert(collect_reachable(wb, "app") == ["ex"]);
}

test "cycle_does_not_hang_and_dedup" {
    wb: Workbench = wb_create("w4");
    root ++> wb;
    app_add(wb, "app");
    ev_add(wb, "app", "x");
    ev_add(wb, "app", "y");
    ev_add(wb, "app", "z");
    assert(ref_add(wb, "x", "y"));
    assert(ref_add(wb, "y", "z"));
    assert(ref_add(wb, "z", "x"));
    r: list[str] = collect_lineage(wb, "x");
    assert(r == ["x", "y", "z"]);
    r2: list[str] = collect_reachable(wb, "app");
    assert(r2 == ["x", "y", "z"]);
}
