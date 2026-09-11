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
