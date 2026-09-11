"""Guard tests for iss_fayazara__opencode-stats__4.jac"""

obj SessionCostStore { has sessions: dict[str, Session] = {}; }
node Session { has sid: str; has cost: int; has tokens: int; }
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

test "buggy roots_only understates subagent spend" {
    st = load_sessions(
        [
            ("main", 100, 1000),
            ("sub1", 80, 800),
            ("sub2", 70, 700),
            ("orphan", 5, 50),
        ],
        [("sub1", "main"), ("sub2", "sub1")],
    );
    assert session_costs(st, "main") == (100, 1000);
    assert session_costs(st, "sub1") == (80, 800);
    assert session_costs(st, "missing") == (0, 0);
    assert roots_only_cost(st) == 105;
    assert total_cost(st, "main") == 250;
    assert all_session_ids(st, "main") == ["main", "sub1", "sub2"];
}

test "unknown root tolerance" {
    st = load_sessions([("only", 1, 10)], []);
    assert total_cost(st, "missing") == 0;
    assert all_session_ids(st, "missing") == [];
}

test "subagent cycle terminates" {
    st = load_sessions(
        [("a", 1, 10), ("b", 2, 20), ("c", 3, 30)],
        [("b", "a"), ("c", "b"), ("a", "c")],
    );
    assert all_session_ids(st, "b") == ["a", "b", "c"];
    assert total_cost(st, "b") == 6;
}

test "adversarial breadth sibling closure" {
    st = load_sessions(
        [
            ("root", 10, 100),
            ("w1", 20, 200),
            ("w2", 30, 300),
            ("w3", 40, 400),
            ("deep", 50, 500),
        ],
        [
            ("w1", "root"),
            ("w2", "root"),
            ("w3", "root"),
            ("deep", "w1"),
        ],
    );
    assert all_session_ids(st, "root") == ["deep", "root", "w1", "w2", "w3"];
    assert total_cost(st, "root") == 150;
}
