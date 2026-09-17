"""
Lift of NousResearch/hermes-agent#70185: desktop sessions silently archived
via compression-lineage cascade; session_key=NULL breaks resume.
"""

node Session {
    has sid: str;
    has source: str = "desktop";
    has session_key: str | None = None;
    has archived: bool = False;
    has audit: list[str] = [];
}

edge CompressionLink {}

glob graph_root: dict[str, Session] = {};

def add_session(sid: str, source: str = "desktop", session_key: str | None = None) -> Session {
    s = Session(sid=sid, source=source, session_key=session_key);
    graph_root[sid] = s;
    return s;
}

def link_compression(prev: Session, nxt: Session) {
    prev +>:CompressionLink:+> nxt;
}

# collect the full compression lineage (ancestors + descendants) via claim-map
walker collect_lineage {
    has claimed: dict[str, bool] = {};
    has lineage: list[str] = [];

    can step with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.lineage.append(here.sid);
        nbrs: list[Session] = [];
        for nb in [here ->:CompressionLink:->][?:Session] { nbrs.append(nb); }
        for nb in [here <-:CompressionLink:-][?:Session] { nbrs.append(nb); }
        visit nbrs;
    }
}

def set_session_archived(sid: str) -> list[str] {
    if sid not in graph_root {
        return [];
    }
    start = graph_root[sid];
    # two-phase: collect during walk, mutate after
    wk = start spawn collect_lineage(claimed={});
    affected: list[str] = [];
    for s in wk.lineage { affected.append(s); }
    affected = sorted(affected);
    for s in affected {
        # `node` is a reserved keyword; use nd
        nd = graph_root[s];
        nd.archived = True;
        nd.audit.append("archived sid=" + s);
    }
    return affected;
}

def unarchive_desktop_sessions -> int {
    n: int = 0;
    for sid in sorted(graph_root.keys()) {
        s = graph_root[sid];
        if s.source == "desktop" and s.archived {
            s.archived = False;
            n = n + 1;
        }
    }
    return n;
}

def find_latest_gateway_session_for_peer(session_key: str) -> str | None {
    best: str | None = None;
    for sid in sorted(graph_root.keys()) {
        s = graph_root[sid];
        if s.session_key == session_key and not s.archived {
            if best is None or sid > best { best = sid; }
        }
    }
    return best;
}

def count_archived -> int {
    n: int = 0;
    for sid in graph_root.keys() {
        if graph_root[sid].archived { n = n + 1; }
    }
    return n;
}

with entry {
    a = add_session("s1", "desktop");
    b = add_session("s2", "desktop");
    c = add_session("s3", "desktop", session_key="peerX");
    link_compression(a, b);
    link_compression(b, c);
    hit = set_session_archived("s2");
    print("cascade archived:", hit);
    print("resume for peerX:", find_latest_gateway_session_for_peer("peerX"));
    print("unarchived:", unarchive_desktop_sessions());
}

test "cascade_archives_lineage" {
    a = add_session("t1_a", "desktop");
    b = add_session("t1_b", "desktop");
    c = add_session("t1_c", "desktop", session_key="peerT1");
    link_compression(a, b);
    link_compression(b, c);
    hit = set_session_archived("t1_b");
    assert sorted(hit) == ["t1_a", "t1_b", "t1_c"];
    assert count_archived() >= 3;
    assert graph_root["t1_a"].audit[0] == "archived sid=t1_a";
}

test "unknown_sid_returns_empty" {
    assert set_session_archived("missing_sid") == [];
}

test "resume_skips_archived" {
    add_session("t2_g1", "gateway", session_key="peerT2");
    add_session("t2_g2", "gateway", session_key="peerT2");
    assert find_latest_gateway_session_for_peer("peerT2") == "t2_g2";
    set_session_archived("t2_g2");
    assert find_latest_gateway_session_for_peer("peerT2") == "t2_g1";
    assert find_latest_gateway_session_for_peer("nope") is None;
}

test "unarchive_only_desktop" {
    add_session("t3_d", "desktop");
    add_session("t3_w", "gateway");
    set_session_archived("t3_d");
    set_session_archived("t3_w");
    n = unarchive_desktop_sessions();
    assert graph_root["t3_d"].archived is False;
    assert graph_root["t3_w"].archived is True;
    assert n >= 1;
}
