node Session {
    has sid: str;
    has status: str = "live";
    has archived: bool = False;
}
edge Spawns {}

walker CollectDescendants {
    has claimed: dict[str, bool] = {};
    has found: list[Session] = [];
    can collect with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.found.append(here);
        for nxt in [here ->:Spawns:->][?:Session] {
            visit :0: [nxt];
        }
        print(here.sid);
    }
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has hit: bool = False;
    can reach with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid == self.target {
            self.hit = True;
            print("hit " + here.sid);
            return;
        }
        for nxt in [here ->:Spawns:->][?:Session] {
            visit :0: [nxt];
        }
        print(here.sid);
    }
}

def make_session(sid: str) -> Session {
    nd = Session(sid=sid);
    root ++> nd;
    return nd;
}

def link_parent(parent: Session, child: Session) {
    parent +>:Spawns:+> child;
}

def get_descendants(start: Session) -> list[Session] {
    w = start spawn CollectDescendants(claimed={});
    res: list[Session] = [];
    for n in w.found {
        if n.sid != start.sid {
            res.append(n);
        }
    }
    return res;
}

def get_live_descendants(start: Session) -> list[Session] {
    all = get_descendants(start);
    live: list[Session] = [];
    for n in all {
        if n.archived == False {
            live.append(n);
        }
    }
    return live;
}

def is_reachable(src: Session, dst: Session) -> bool {
    if src.sid == dst.sid {
        return True;
    }
    w = src spawn ReachWalker(claimed={}, target=dst.sid);
    return w.hit;
}

with entry {
    demo_a = Session(sid="demo-a");
    root ++> demo_a;
    demo_b = Session(sid="demo-b");
    root ++> demo_b;
    demo_a +>:Spawns:+> demo_b;
    w = demo_a spawn CollectDescendants(claimed={});
    root spawn CollectDescendants(claimed={});
    print("demo done");
}

test "diamond adversarial order collects all" {
    a = Session(sid="a-diamond");
    root ++> a;
    b = Session(sid="b-diamond");
    root ++> b;
    c = Session(sid="c-diamond");
    root ++> c;
    d = Session(sid="d-diamond");
    root ++> d;
    link_parent(a, c);
    link_parent(a, b);
    link_parent(c, d);
    link_parent(b, d);
    res = get_descendants(a);
    sids: list[str] = [];
    for n in res { sids.append(n.sid); }
    sids = sorted(sids);
    assert sids == ["b-diamond", "c-diamond", "d-diamond"];
}

test "cycle does not hang and dedups via claim-map" {
    x = Session(sid="x-cycle");
    root ++> x;
    y = Session(sid="y-cycle");
    root ++> y;
    z = Session(sid="z-cycle");
    root ++> z;
    link_parent(x, y);
    link_parent(y, z);
    link_parent(z, x);
    res = get_descendants(x);
    sids: list[str] = [];
    for n in res { sids.append(n.sid); }
    sids = sorted(sids);
    assert sids == ["y-cycle", "z-cycle"];
    assert is_reachable(x, z) == True;
    assert is_reachable(z, y) == True;
}

test "unknown isolated not reachable and empty closure" {
    p = Session(sid="p-iso");
    root ++> p;
    q = Session(sid="q-iso");
    root ++> q;
    r = Session(sid="r-iso");
    root ++> r;
    assert is_reachable(p, q) == False;
    assert is_reachable(p, p) == True;
    res = get_descendants(p);
    assert len(res) == 0;
    res2 = get_descendants(q);
    assert len(res2) == 0;
}

test "live filter excludes archived descendant" {
    lead = Session(sid="lead-live");
    root ++> lead;
    c1 = Session(sid="c1-live", archived=False);
    root ++> c1;
    c2 = Session(sid="c2-arch", archived=True);
    root ++> c2;
    c3 = Session(sid="c3-live2", archived=False);
    root ++> c3;
    link_parent(lead, c1);
    link_parent(lead, c2);
    link_parent(c1, c3);
    all = get_descendants(lead);
    all_sids: list[str] = [];
    for n in all { all_sids.append(n.sid); }
    all_sids = sorted(all_sids);
    assert all_sids == ["c1-live", "c2-arch", "c3-live2"];
    live = get_live_descendants(lead);
    live_sids: list[str] = [];
    for n in live { live_sids.append(n.sid); }
    live_sids = sorted(live_sids);
    assert live_sids == ["c1-live", "c3-live2"];
}
