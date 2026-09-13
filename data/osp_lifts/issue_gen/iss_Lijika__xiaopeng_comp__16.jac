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
