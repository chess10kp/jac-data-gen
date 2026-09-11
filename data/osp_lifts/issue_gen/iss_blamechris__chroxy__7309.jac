"""blamechris/chroxy#7309 — indexed session query (OSP lift)."""

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
