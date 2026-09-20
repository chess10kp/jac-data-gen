# iss_NousResearch__hermes-agent__70185.jac
# NousResearch/hermes-agent#70185 — compression-lineage CTE cascade + session_key resume.

node Session {
    has sid: str;
    has session_key: str = "";
    has archived: int = 0;
    has end_reason: str = "";
    has chat_id: str = "";
    has user_id: str = "";
    has chat_type: str = "";
    has source: str = "";
}

edge Compression {}

obj SessionStore {
    has graph_root: Session;
    has by_sid: dict[str, Session] = {};
}

walker LineageCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.found.append(here.sid);
        print(here.sid);
        nbrs: list[Session] = [];
        for anc in [<-:Compression:<-][?:Session] {
            nbrs.append(anc);
        }
        for desc in [->:Compression:->][?:Session] {
            nbrs.append(desc);
        }
        if nbrs {
            visit :0: nbrs;
        } else {
            disengage;
        }
    }
}

def new_store() -> SessionStore {
    anchor = Session(sid="__anchor__");
    root ++> anchor;
    return SessionStore(graph_root=anchor);
}

def add_session(store: SessionStore, sid: str, session_key: str, archived: int, end_reason: str, chat_id: str, user_id: str, chat_type: str, source: str) -> Session {
    s = Session(sid=sid, session_key=session_key, archived=archived, end_reason=end_reason, chat_id=chat_id, user_id=user_id, chat_type=chat_type, source=source);
    store.graph_root ++> s;
    store.by_sid[sid] = s;
    return s;
}

def link_compression(parent: Session, child: Session) {
    parent +>:Compression:+> child;
}

def compression_lineage_ids(store: SessionStore, root_sid: str) -> list[str] {
    if root_sid not in store.by_sid {
        return [];
    }
    nd = store.by_sid[root_sid] as Session;
    w = nd spawn LineageCollect(claimed={});
    out: list[str] = [];
    for x in w.found {
        out.append(x);
    }
    return sorted(out);
}

def set_session_archived(store: SessionStore, root_sid: str) -> list[str] {
    ids = compression_lineage_ids(store, root_sid);
    for sid in ids {
        s = store.by_sid[sid] as Session;
        s.archived = 1;
    }
    return sorted(ids);
}

def find_latest_gateway_session_for_peer(store: SessionStore, session_key: str, chat_id: str, user_id: str, chat_type: str) -> str | None {
    latest: str | None = None;
    keys: list[str] = [];
    for k in store.by_sid {
        keys.append(k);
    }
    keys = sorted(keys);
    if session_key != "" {
        for sid in keys {
            s = store.by_sid[sid] as Session;
            if s.archived != 0 { continue; }
            if s.session_key == session_key {
                latest = sid;
            }
        }
        if latest is not None { return latest; }
    }
    if chat_id != "" or user_id != "" or chat_type != "" {
        for sid in keys {
            s = store.by_sid[sid] as Session;
            if s.archived != 0 { continue; }
            if s.chat_id == chat_id and s.user_id == user_id and s.chat_type == chat_type {
                latest = sid;
            }
        }
    }
    return latest;
}
