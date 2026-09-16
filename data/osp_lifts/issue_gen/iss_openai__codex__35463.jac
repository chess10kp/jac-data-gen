"""openai/codex#35463 — fork lineage replays ancestor token bookkeeping."""

node Session {
    has sid: str;
    has genuine: int = 0;
    has replay: int = 0;
}

edge Fork {}

def make_ledger() -> Session {
    anchor = Session(sid="__anchor__", genuine=0, replay=0);
    return anchor;
}

def gather_children(here: Session) -> list[Session] {
    out: list[Session] = [];
    if here.sid == "__anchor__" {
        links = [here ->];
        for item in links {
            ch = item as Session;
            out.append(ch);
        }
    } else {
        fork_kids: list[Session] = [here ->:Fork:->][?:Session];
        for ch in fork_kids {
            out.append(ch);
        }
    }
    return out;
}

def find_session(graph_root: Session, sid: str) -> Session | None {
    w = graph_root spawn FindSession(claimed={}, target=sid);
    return w.found;
}

walker FindSession {
    has claimed: dict[str, bool] = {};
    has target: str;
    has found: Session | None = None;

    can step with Session entry {
        if here.sid == self.target {
            self.found = here;
            print("find_hit", here.sid);
            disengage;
        }
        if here.sid != "__anchor__" {
            if here.sid in self.claimed {
                skip;
            }
            self.claimed[here.sid] = True;
        }
        kids: list[Session] = gather_children(here);
        visit :0: kids else { disengage; }
    }
}

def add_root_session(graph_root: Session, sid: str, genuine_events: int) -> Session {
    nd = Session(sid=sid, genuine=genuine_events, replay=0);
    graph_root ++> nd;
    return nd;
}

def fork_child(
    graph_root: Session,
    parent_sid: str,
    child_sid: str,
    genuine_events: int,
) -> Session | None {
    parent: Session | None = find_session(graph_root, parent_sid);
    if parent is None {
        return None;
    }
    inherited: int = parent.genuine + parent.replay;
    ch = Session(sid=child_sid, genuine=genuine_events, replay=inherited);
    parent +>:Fork:+> ch;
    return ch;
}

def reported_events(graph_root: Session, sid: str) -> int {
    nd: Session | None = find_session(graph_root, sid);
    if nd is None {
        return -1;
    }
    return nd.genuine + nd.replay;
}

def genuine_events_only(graph_root: Session, sid: str) -> int {
    nd: Session | None = find_session(graph_root, sid);
    if nd is None {
        return -1;
    }
    return nd.genuine;
}

def naive_tree_reported(graph_root: Session) -> int {
    w = graph_root spawn SumReported(claimed={});
    print("naive_total", w.total);
    return w.total;
}

walker SumReported {
    has claimed: dict[str, bool] = {};
    has total: int = 0;

    can step with Session entry {
        if here.sid != "__anchor__" {
            if here.sid in self.claimed {
                skip;
            }
            self.claimed[here.sid] = True;
            self.total = self.total + here.genuine + here.replay;
            print("reported_add", here.sid);
        }
        kids: list[Session] = gather_children(here);
        visit :0: kids else { disengage; }
    }
}

def real_tree_usage(graph_root: Session) -> int {
    w = graph_root spawn SumGenuine(claimed={});
    print("real_total", w.total);
    return w.total;
}

walker SumGenuine {
    has claimed: dict[str, bool] = {};
    has total: int = 0;

    can step with Session entry {
        if here.sid != "__anchor__" {
            if here.sid in self.claimed {
                skip;
            }
            self.claimed[here.sid] = True;
            self.total = self.total + here.genuine;
            print("genuine_add", here.sid);
        }
        kids: list[Session] = gather_children(here);
        visit :0: kids else { disengage; }
    }
}

def fork_depth(graph_root: Session, sid: str) -> int {
    nd: Session | None = find_session(graph_root, sid);
    if nd is None {
        return -1;
    }
    w = nd spawn DepthUp(claimed={}, depth=0);
    print("depth", sid, w.depth);
    return w.depth;
}

walker DepthUp {
    has claimed: dict[str, bool] = {};
    has depth: int = 0;

    can ascend with Session entry {
        if here.sid == "__anchor__" {
            disengage;
        }
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        parents: list[Session] = [->:Fork:-> here][?:Session];
        if len(parents) == 0 {
            links = [-> here];
            for item in links {
                par = item as Session;
                parents.append(par);
            }
        }
        if len(parents) == 0 {
            disengage;
        }
        par: Session = parents[0];
        if par.sid != "__anchor__" {
            self.depth = self.depth + 1;
        }
        visit :0: [par] else { disengage; }
    }
}
