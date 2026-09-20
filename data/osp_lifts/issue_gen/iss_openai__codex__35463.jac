"""Subagent fork-tree token replay accounting — openai/codex#35463."""

node Session {
    has sid: str;
    has parent_sid: str = "";
    has inp: int = 0;
    has cached: int = 0;
    has out: int = 0;
    has replay_inp: int = 0;
    has replay_cached: int = 0;
    has replay_out: int = 0;
    has events: int = 0;
    has replay_events: int = 0;
}

edge Fork {}

glob graph_root: Session = Session(sid="__root__");

def find_session(sid: str) -> Session | None {
    for nd in [-->:Session] {
        if nd.sid == sid {
            return nd;
        }
    }
    return None;
}

def register_session(parent_id: str | None, sid: str) -> bool {
    if sid == "__root__" {
        return False;
    }
    if find_session(sid) != None {
        return False;
    }
    if parent_id != None {
        if find_session(parent_id) == None {
            return False;
        }
    }
    nd: Session = Session(sid=sid);
    graph_root ++> nd;
    if parent_id != None {
        par: Session | None = find_session(parent_id);
        if par != None {
            par +>:Fork:+> nd;
            nd.parent_sid = parent_id;
        }
    }
    return True;
}

def log_tokens(sid: str, inp: int, cached: int, out: int, replayed: bool) -> bool {
    nd: Session | None = find_session(sid);
    if nd == None {
        return False;
    }
    if replayed {
        nd.replay_inp += inp;
        nd.replay_cached += cached;
        nd.replay_out += out;
        nd.replay_events += 1;
    } else {
        nd.inp += inp;
        nd.cached += cached;
        nd.out += out;
        nd.events += 1;
    }
    return True;
}

def inherit_lineage_burst(child_id: str) -> int {
    child: Session | None = find_session(child_id);
    if child == None {
        return -1;
    }
    if child.parent_sid == "" {
        return 0;
    }
    par: Session | None = find_session(child.parent_sid);
    if par == None {
        return -1;
    }
    replayed: int = par.events + par.replay_events;
    child.replay_inp += par.inp + par.replay_inp;
    child.replay_cached += par.cached + par.replay_cached;
    child.replay_out += par.out + par.replay_out;
    child.replay_events += replayed;
    return replayed;
}

def naive_totals -> dict[str, int] {
    tot: dict[str, int] = {};
    tot["input"] = 0;
    tot["cached"] = 0;
    tot["output"] = 0;
    for nd in [-->:Session] {
        if nd.sid == "__root__" {
            continue;
        }
        tot["input"] += nd.inp + nd.replay_inp;
        tot["cached"] += nd.cached + nd.replay_cached;
        tot["output"] += nd.out + nd.replay_out;
    }
    return tot;
}

def real_totals -> dict[str, int] {
    tot: dict[str, int] = {};
    tot["input"] = 0;
    tot["cached"] = 0;
    tot["output"] = 0;
    for nd in [-->:Session] {
        if nd.sid == "__root__" {
            continue;
        }
        tot["input"] += nd.inp;
        tot["cached"] += nd.cached;
        tot["output"] += nd.out;
    }
    return tot;
}

def fork_depth(sid: str) -> int {
    nd: Session | None = find_session(sid);
    if nd == None {
        return -1;
    }
    depth: int = 0;
    cur_sid: str = nd.parent_sid;
    while cur_sid != "" {
        depth += 1;
        par: Session | None = find_session(cur_sid);
        if par == None {
            return -1;
        }
        cur_sid = par.parent_sid;
    }
    return depth;
}

def add_convergent_fork(parent_id: str, child_id: str) -> bool {
    par: Session | None = find_session(parent_id);
    ch: Session | None = find_session(child_id);
    if par == None or ch == None {
        return False;
    }
    par +>:Fork:+> ch;
    return True;
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];

    can collect with Session entry {
        print([f"desc {here.sid}"]);
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        self.out.append(here.sid);
        kids: list[Session] = [here ->:Fork:->][?:Session];
        for ch in kids {
            visit :0: ch;
        }
    }
}

walker LineageKick {
    has origin_sid: str;
    has done: bool = False;

    can launch with Session entry {
        print(["lineage-kick"]);
        self.done = True;
        tgt: Session | None = find_session(self.origin_sid);
        if tgt is not None {
            visit tgt;
        }
        disengage;
    }
}

def list_descendants(root_sid: str) -> list[str] {
    origin: Session | None = find_session(root_sid);
    if origin is None {
        return [];
    }
    w: DescendantWalk = origin spawn DescendantWalk();
    res: list[str] = sorted(w.out);
    return res;
}
