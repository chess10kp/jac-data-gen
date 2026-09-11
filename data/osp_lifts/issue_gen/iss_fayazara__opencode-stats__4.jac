"""fayazara/opencode-stats#4 — subagent cost rollup (OSP lift)."""

obj SessionCostStore {
    has sessions: dict[str, Session] = {};
}

node Session {
    has sid: str;
    has cost: int;
    has tokens: int;
}

edge SubagentOf {}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_sid: str = "";

    can step with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid != self.start_sid { self.reached.append(here.sid); }
        for ch in [here <-:SubagentOf:<-] { visit [ch]; }
    }
}

def load_sessions(
    sessions: list[tuple[str, int, int]],
    subagents: list[tuple[str, str]],
) -> SessionCostStore {
    st = SessionCostStore();
    for (sid, cost, tokens) in sessions {
        s = Session(sid=sid, cost=cost, tokens=tokens);
        root ++> s;
        st.sessions[sid] = s;
    }
    for (child, par) in subagents {
        c = st.sessions.get(child, None);
        p = st.sessions.get(par, None);
        if c is not None and p is not None { c +>:SubagentOf:+> p; }
    }
    return st;
}

def session_costs(st: SessionCostStore, sid: str) -> tuple[int, int] {
    s = st.sessions.get(sid, None);
    if s is None { return (0, 0); }
    return (s.cost, s.tokens);
}

def roots_only_cost(st: SessionCostStore) -> int {
    total = 0;
    for (_sid, sess) in st.sessions.items() {
        parents = [sess ->:SubagentOf:->];
        if len(parents) == 0 { total += sess.cost; }
    }
    return total;
}

def total_cost(st: SessionCostStore, root_sid: str) -> int {
    anchor = st.sessions.get(root_sid, None);
    if anchor is None { return 0; }
    w = anchor spawn DescendantWalk(claimed={}, reached=[], start_sid=root_sid);
    total = anchor.cost;
    for sid in w.reached {
        child = st.sessions.get(sid, None);
        if child is not None { total += child.cost; }
    }
    return total;
}

def all_session_ids(st: SessionCostStore, root_sid: str) -> list[str] {
    anchor = st.sessions.get(root_sid, None);
    if anchor is None { return []; }
    w = anchor spawn DescendantWalk(claimed={}, reached=[], start_sid=root_sid);
    return sorted([root_sid] + w.reached);
}
