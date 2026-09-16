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
