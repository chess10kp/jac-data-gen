"""Pascapone/pibo#676 models payload cleanup during permanent session deletion."""

node GraphRoot {}

node Session {
    has sid: str;
    has deleted: bool = False;
}

node Message {
    has mid: str;
    has session_id: str;
    has payload_id: str;
    has deleted: bool = False;
}

node Payload {
    has pid: str;
    has content: str;
    has ref_count: int = 0;
    has file_exists: bool = True;
    has deleted: bool = False;
}

edge HasSession {}
edge HasMessage {}
edge UsesPayload {}

obj Store {
    has graph_root: GraphRoot;
}

walker CollectDeletion {
    has target: str;
    has claimed: dict[str, bool] = {};
    has sessions: list[Session] = [];
    has messages: list[Message] = [];
    has payloads: list[Payload] = [];
    has payload_deltas: dict[str, int] = {};

    can collect_root with GraphRoot entry {
        print("collect-root");
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for session in [here ->:HasSession:->][?:Session] {
            if session.sid == self.target {
                visit :0: [session];
            }
        }
    }

    can collect_session with Session entry {
        print("collect-session");
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.deleted { skip; }
        if here.sid != self.target { skip; }
        self.sessions.append(here);
        for message in [here ->:HasMessage:->][?:Message] {
            visit :0: [message];
        }
    }

    can collect_message with Message entry {
        print("collect-message");
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.deleted { skip; }
        self.messages.append(here);
        for payload in [here ->:UsesPayload:->][?:Payload] {
            if payload.pid in self.payload_deltas {
                self.payload_deltas[payload.pid] += 1;
            } else {
                self.payload_deltas[payload.pid] = 1;
            }
            visit :0: [payload];
        }
    }

    can collect_payload with Payload entry {
        print("collect-payload");
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.payloads.append(here);
    }
}

def create_store -> Store {
    graph_root = GraphRoot();
    return Store(graph_root=graph_root);
}

def create_session(store: Store, session_id: str) -> Session {
    session = Session(sid=session_id);
    store.graph_root +>:HasSession:+> session;
    return session;
}

def create_payload(payload_id: str, content: str) -> Payload {
    return Payload(pid=payload_id, content=content);
}

def ingest_message(
    session: Session, message_id: str, payload: Payload
) -> Message {
    message = Message(
        mid=message_id,
        session_id=session.sid,
        payload_id=payload.pid,
    );
    session +>:HasMessage:+> message;
    message +>:UsesPayload:+> payload;
    payload.ref_count += 1;
    payload.deleted = False;
    payload.file_exists = True;
    return message;
}

def delete_session(store: Store, session_id: str) -> int {
    w = store.graph_root spawn CollectDeletion(target=session_id);
    if len(w.sessions) == 0 {
        return 0;
    }

    session_node: Session = w.sessions[0];
    for message in w.messages {
        for payload in w.payloads {
            if payload.pid == message.payload_id {
                message -:UsesPayload:-> payload;
            }
        }
        session_node -:HasMessage:-> message;
        message.deleted = True;
    }
    store.graph_root -:HasSession:-> session_node;
    session_node.deleted = True;

    for payload in w.payloads {
        payload.ref_count -= w.payload_deltas[payload.pid];
        if payload.ref_count <= 0 {
            payload.ref_count = 0;
            payload.file_exists = False;
            payload.deleted = True;
        }
    }
    return 1;
}

test "adversarial diamond revisits shared payload once" {
    store = create_store();
    session_a = create_session(store, "s-a");
    session_b = create_session(store, "s-b");
    shared = create_payload("p-shared", "shared");
    other = create_payload("p-other", "other");
    ingest_message(session_a, "m-first", shared);
    ingest_message(session_a, "m-other", other);
    ingest_message(session_a, "m-second", shared);
    ingest_message(session_b, "m-third", shared);
    assert (shared.ref_count == 3);
    assert (delete_session(store, "s-a") == 1);
    assert (shared.ref_count == 1);
    assert (other.ref_count == 0);
    assert (other.file_exists == False);
    assert (shared.file_exists == True);
}

test "unknown session deletion is tolerated" {
    store = create_store();
    payload = create_payload("p-unknown", "data");
    assert (delete_session(store, "missing") == 0);
    assert (payload.ref_count == 0);
    assert (payload.file_exists == True);
}

test "empty session and repeated deletion are harmless" {
    store = create_store();
    create_session(store, "empty");
    assert (delete_session(store, "empty") == 1);
    assert (delete_session(store, "empty") == 0);
}

test "last owner releases payload file" {
    store = create_store();
    session = create_session(store, "only");
    payload = create_payload("p-only", "");
    ingest_message(session, "m-only", payload);
    assert (payload.ref_count == 1);
    assert (delete_session(store, "only") == 1);
    assert (payload.ref_count == 0);
    assert (payload.file_exists == False);
    assert (payload.deleted == True);
}
