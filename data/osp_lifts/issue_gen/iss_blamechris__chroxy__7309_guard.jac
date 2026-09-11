"""blamechris/chroxy#7309 — candidate + hidden guards."""

obj SessionStore {
    has sessions: dict[str, Session] = {};
    has token_index: dict[str, list[str]] = {};
}

node Session {
    has sid: str;
    has project: str;
    has provider: str;
    has corpus: list[tuple[str, str]] = [];
    has live_msgs: list[tuple[str, str]] = [];
}

edge ForkOf {}
edge SubagentOf {}

walker LineageWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_sid: str = "";

    can step with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid != self.start_sid { self.reached.append(here.sid); }
        visit [here ->:ForkOf:->] else { disengage; };
    }
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_sid: str = "";

    can step with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid != self.start_sid { self.reached.append(here.sid); }
        for ch in [here <-:ForkOf:<-] { visit [ch]; }
        for ch in [here <-:SubagentOf:<-] { visit [ch]; }
    }
}

def _index_tokens(st: SessionStore, sid: str, text: str) {
    for tok in text.lower().split() {
        if tok not in st.token_index { st.token_index[tok] = []; }
        if sid not in st.token_index[tok] { st.token_index[tok].append(sid); }
    }
}

def load_sessions(
    sessions: list[tuple[str, str, str]],
    forks: list[tuple[str, str]],
    subagents: list[tuple[str, str]],
    messages: list[tuple[str, str, str]],
    live: list[tuple[str, str, str]],
) -> SessionStore {
    st = SessionStore();
    for (sid, proj, prov) in sessions {
        s = Session(sid=sid, project=proj, provider=prov);
        root ++> s;
        st.sessions[sid] = s;
    }
    for (child, par) in forks {
        c = st.sessions.get(child, None);
        p = st.sessions.get(par, None);
        if c is not None and p is not None { c +>:ForkOf:+> p; }
    }
    for (child, par) in subagents {
        c = st.sessions.get(child, None);
        p = st.sessions.get(par, None);
        if c is not None and p is not None { c +>:SubagentOf:+> p; }
    }
    for (sid, role, text) in messages {
        sess = st.sessions.get(sid, None);
        if sess is None { continue; }
        sess.corpus = sess.corpus + [(role, text)];
        _index_tokens(st, sid, text);
    }
    for (sid, role, text) in live {
        sess = st.sessions.get(sid, None);
        if sess is None { continue; }
        sess.live_msgs = sess.live_msgs + [(role, text)];
    }
    return st;
}

def search(st: SessionStore, query: str, project: str | None = None, role: str | None = None) -> list[str] {
    ql = query.lower();
    hits: dict[str, bool] = {};
    for (sid, sess) in st.sessions.items() {
        if project is not None and sess.project != project { continue; }
        for (r, txt) in sess.live_msgs {
            if role is not None and r != role { continue; }
            if ql in txt.lower() { hits[sid] = True; }
        }
    }
    toks = ql.split();
    pool: list[str] | None = None;
    for t in toks {
        bucket = st.token_index.get(t, []);
        if pool is None { pool = bucket; }
        else {
            nxt: list[str] = [];
            for x in pool { if x in bucket { nxt.append(x); } }
            pool = nxt;
        }
    }
    if pool is not None {
        for sid in pool {
            sess = st.sessions.get(sid, None);
            if sess is None { continue; }
            if project is not None and sess.project != project { continue; }
            if role is not None {
                ok = False;
                for (r, txt) in sess.corpus {
                    if r == role and ql in txt.lower() { ok = True; }
                }
                if not ok { continue; }
            }
            hits[sid] = True;
        }
    }
    out: list[str] = [];
    for k in hits { out.append(k); }
    return sorted(out);
}

def lineage(st: SessionStore, sid: str) -> list[str] {
    anchor = st.sessions.get(sid, None);
    if anchor is None { return []; }
    w = anchor spawn LineageWalk(claimed={}, reached=[], start_sid=sid);
    return sorted(w.reached);
}

def descendants(st: SessionStore, sid: str) -> list[str] {
    anchor = st.sessions.get(sid, None);
    if anchor is None { return []; }
    w = anchor spawn DescendantWalk(claimed={}, reached=[], start_sid=sid);
    return sorted(w.reached);
}

def search_scoped(st: SessionStore, query: str, anchor_sid: str) -> list[str] {
    scope: dict[str, bool] = {};
    scope[anchor_sid] = True;
    for x in lineage(st, anchor_sid) { scope[x] = True; }
    for x in descendants(st, anchor_sid) { scope[x] = True; }
    all_hits = search(st, query);
    out: list[str] = [];
    for h in all_hits { if h in scope { out.append(h); } }
    return out;
}

def _fixture() -> SessionStore {
    return load_sessions(
        [
            ("s1", "proj-a", "openai"),
            ("s2", "proj-a", "openai"),
            ("s3", "proj-b", "anthropic"),
            ("s4", "proj-a", "openai"),
        ],
        [("s2", "s1"), ("s4", "s2")],
        [("s3", "s1")],
        [
            ("s1", "user", "deploy indexed session query"),
            ("s2", "user", "fork discussion about deploy"),
            ("s4", "user", "nested fork thread"),
        ],
        [("s1", "assistant", "live tail about indexing now")],
    );
}

test "indexed search live-preferred and filters" {
    st = _fixture();
    assert search(st, "indexing") == ["s1"];
    assert search(st, "deploy") == ["s1", "s2"];
    assert search(st, "deploy", project="proj-b") == [];
    assert search(st, "deploy", role="user") == ["s1", "s2"];
    assert lineage(st, "s4") == ["s1", "s2"];
    assert descendants(st, "s1") == ["s2", "s3", "s4"];
    assert search_scoped(st, "discussion", "s1") == ["s2"];
    assert search_scoped(st, "nested", "s1") == ["s4"];
}

test "unknown session tolerance" {
    st = _fixture();
    assert lineage(st, "missing") == [];
    assert descendants(st, "missing") == [];
    assert search(st, "ghost") == [];
}

test "fork cycle lineage and descendants terminate" {
    st = load_sessions(
        [("a", "p", "x"), ("b", "p", "x"), ("c", "p", "x")],
        [("b", "a"), ("c", "b"), ("a", "c")],
        [],
        [],
        [],
    );
    assert lineage(st, "b") == ["a", "c"];
    assert descendants(st, "a") == ["b", "c"];
}

test "adversarial breadth sibling descendants" {
    st = load_sessions(
        [
            ("root", "p", "x"),
            ("w1", "p", "x"),
            ("w2", "p", "x"),
            ("w3", "p", "x"),
            ("deep", "p", "x"),
        ],
        [("w1", "root"), ("w2", "root"), ("w3", "root"), ("deep", "w1")],
        [],
        [
            ("w1", "user", "alpha transcript"),
            ("w2", "user", "beta transcript"),
            ("w3", "user", "gamma transcript"),
            ("deep", "user", "delta nested transcript"),
        ],
        [],
    );
    assert descendants(st, "root") == ["deep", "w1", "w2", "w3"];
    assert search_scoped(st, "transcript", "root") == ["deep", "w1", "w2", "w3"];
}
