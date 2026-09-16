# Lift of NousResearch/hermes-agent#70185
# Desktop sessions silently archived via compression-lineage cascade;
# session_key=NULL prevents gateway resume. Session nodes connected by
# Compression edges; archiving one cascades bidirectionally (ancestors
# AND descendants) via a claim-map walker with skip-based cycle policy.

node Session {
    has sid: str;
    has archived: bool = False;
    has session_key: str | None = None;
    has source: str = "desktop";
}

edge Compression { }

def make_session(sid: str, session_key: str | None = None, source: str = "desktop") -> Session {
    s = Session(sid=sid, session_key=session_key, source=source);
    root ++> s;
    return s;
}

def link_compression(a: Session, b: Session) {
    a +>:Compression:+> b;
}

def find_session(sid: str) -> Session | None {
    all: list[Session] = [];
    for s in [root ->][?:Session] { all.append(s); }
    for s in all {
        if s.sid == sid { return s; }
    }
    return None;
}

walker ArchiveCascade {
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];
    can step with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.collected.append(here.sid);
        kids: list[Session] = [];
        for ch in [here ->:Compression:->][?:Session] { kids.append(ch); }
        for ch in [here <-:Compression:-][?:Session] { kids.append(ch); }
        visit kids else { disengage; }
    }
}

# Two-phase mutation: walker only COLLECTS the closure; archive writes
# happen after the walk completes (never inside a walk).
def set_session_archived(sid: str) -> list[str] {
    start = find_session(sid);
    if start is None { return []; }
    wk = start spawn ArchiveCascade(claimed={}, collected=[]);
    hit: list[str] = [];
    for s in [root ->][?:Session] {
        if s.sid in wk.collected {
            s.archived = True;
            hit.append(s.sid);
        }
    }
    return sorted(hit);
}

def count_cascade(sid: str) -> int {
    return len(set_session_archived(sid));
}

def list_archived() -> list[str] {
    out: list[str] = [];
    for s in [root ->][?:Session] {
        if s.archived { out.append(s.sid); }
    }
    return sorted(out);
}

# Gateway resume lookup: session_key is the primary key; when NULL on
# desktop sessions the fallback gateway fields do not resolve either,
# so the resume path returns None and a fresh session is created.
def find_latest_gateway_session_for_peer(sid: str) -> Session | None {
    start = find_session(sid);
    if start is None { return None; }
    if start.session_key is None { return None; }
    best: Session | None = None;
    best_sid: str = "";
    for s in [root ->][?:Session] {
        if s.session_key == start.session_key and not s.archived {
            if best is None {
                best = s;
                best_sid = s.sid;
            } else {
                if s.sid > best_sid {
                    best = s;
                    best_sid = s.sid;
                }
            }
        }
    }
    return best;
}

def unarchive_by_source(src: str) -> list[str] {
    out: list[str] = [];
    for s in [root ->][?:Session] {
        if s.source == src and s.archived {
            s.archived = False;
            out.append(s.sid);
        }
    }
    return sorted(out);
}

test "cascade_archive_descendants_and_ancestors" {
    a = root spawn make_session("s1", "k1");
    b = root spawn make_session("s2", "k2");
    c = root spawn make_session("s3", "k3");
    link_compression(a, b);
    link_compression(b, c);
    hit = set_session_archived("s2");
    assert sorted(hit) == ["s1", "s2", "s3"];
    assert sorted(list_archived()) == ["s1", "s2", "s3"];
}

test "cycle_in_compression_graph_does_not_loop" {
    a = root spawn make_session("c1");
    b = root spawn make_session("c2");
    link_compression(a, b);
    link_compression(b, a);
    assert count_cascade("c1") == 2;
}

test "unknown_sid_returns_empty" {
    assert set_session_archived("nope") == [];
    assert count_cascade("nope") == 0;
    assert find_latest_gateway_session_for_peer("nope") is None;
}

test "null_session_key_blocks_gateway_resume" {
    x = root spawn make_session("d1", None, "desktop");
    y = root spawn make_session("d2", None, "desktop");
    link_compression(x, y);
    set_session_archived("d1");
    assert find_latest_gateway_session_for_peer("d2") is None;
    un = unarchive_by_source("desktop");
    assert sorted(un) == ["d1", "d2"];
    assert find_latest_gateway_session_for_peer("d2") is None;
}

test "gateway_resume_picks_largest_sid_non_archived" {
    p = root spawn make_session("g0", "keyA");
    root spawn make_session("g1", "keyA");
    root spawn make_session("g2", "keyA");
    set_session_archived("g2");
    best = find_latest_gateway_session_for_peer("g0");
    assert best is not None;
    if best is not None { assert best.sid == "g1"; }
}
