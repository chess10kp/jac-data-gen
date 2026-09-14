# PROGRAM iss_TrillionniumFoundation__trillionnium-os__3.jac
"""TrillionniumFoundation/trillionnium-os#3: asynchronous Direct Agent Host lineage."""

edge TurnOf {}
edge Emits {}
edge Link {}

node Connection {
    has connection_id: str;
    has active_stream: str = "";
}

node Turn {
    has turn_stream_id: str;
    has request: str;
    has status: str = "running";
    has canceled: bool = False;
    has terminal: bool = False;
}

node TurnEvent {
    has event_id: str;
    has kind: str;
    has text: str;
    has call_id: str = "none";
}

walker ActiveTurnWalker {
    has requested_id: str;
    has targets: list[Turn] = [];
    has matched: bool = False;
    has claimed: dict[str, bool] = {};

    can locate_connection with Connection entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for turn in [here ->:TurnOf:->][?:Turn] {
            visit :0: [turn];
        }
        print("host connection scanned");
    }

    can locate_turn with Turn entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.turn_stream_id == self.requested_id {
            self.targets.append(here);
            self.matched = True;
        }
        for linked in [here ->:Link:->][?:Turn] {
            visit :0: [linked];
        }
        print("turn lineage scanned");
    }
}

walker EventTrailWalker {
    has events: list[str] = [];
    has claimed: dict[str, bool] = {};

    can trail_turn with Turn entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for event in [here ->:Emits:->][?:TurnEvent] {
            visit :0: [event];
        }
        for linked in [here ->:Link:->][?:Turn] {
            visit :0: [linked];
        }
        print("turn trail scanned");
    }

    can trail_event with TurnEvent entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.events.append(here.event_id);
        print("turn event observed");
    }
}

def new_connection(connection_id: str) -> Connection {
    conn = Connection(connection_id=connection_id);
    return conn;
}

def hello(conn: Connection) -> str {
    return "hello:" + conn.connection_id;
}

def start_turn(conn: Connection, stream_id: str, request: str) -> str {
    w: ActiveTurnWalker = conn spawn ActiveTurnWalker(requested_id=stream_id);
    if len(w.targets) > 0 {
        existing: Turn = w.targets[0];
        if existing.request == request {
            return "attached";
        }
        return "turn_conflict";
    }
    if conn.active_stream != "" {
        return "turn_already_active";
    }
    turn = Turn(turn_stream_id=stream_id, request=request);
    conn +>:TurnOf:+> turn;
    conn.active_stream = stream_id;
    return "started";
}

def publish_event(
    conn: Connection,
    stream_id: str,
    event_id: str,
    kind: str,
    text: str,
    call_id: str = ""
) -> str {
    w: ActiveTurnWalker = conn spawn ActiveTurnWalker(requested_id=stream_id);
    if len(w.targets) == 0 {
        return "unknown_turn";
    }
    turn: Turn = w.targets[0];
    if turn.terminal and kind != "turn.end" {
        return "terminal";
    }
    if turn.terminal and kind == "turn.end" {
        return "already_terminal";
    }
    normalized: str = "none";
    if call_id != "" {
        if call_id.startswith("call_") {
            normalized = call_id;
        } else {
            normalized = "call_" + call_id;
        }
    }
    event = TurnEvent(
        event_id=event_id,
        kind=kind,
        text=text,
        call_id=normalized
    );
    turn +>:Emits:+> event;
    if kind == "turn.end" {
        turn.status = "done";
        turn.terminal = True;
        if conn.active_stream == stream_id {
            conn.active_stream = "";
        }
    }
    return "published";
}

def cancel_turn(conn: Connection, stream_id: str) -> str {
    w: ActiveTurnWalker = conn spawn ActiveTurnWalker(requested_id=stream_id);
    if len(w.targets) == 0 {
        return "unknown_turn";
    }
    turn: Turn = w.targets[0];
    if turn.terminal {
        return "already_terminal";
    }
    turn.canceled = True;
    turn.status = "canceled";
    turn.terminal = True;
    if conn.active_stream == stream_id {
        conn.active_stream = "";
    }
    event = TurnEvent(
        event_id=stream_id + ":end",
        kind="turn.end",
        text="canceled"
    );
    turn +>:Emits:+> event;
    return "canceled";
}

def cancel_tool(conn: Connection, stream_id: str, call_id: str) -> str {
    w: ActiveTurnWalker = conn spawn ActiveTurnWalker(requested_id=stream_id);
    if len(w.targets) == 0 {
        return "unknown_turn";
    }
    turn: Turn = w.targets[0];
    if turn.terminal {
        return "already_terminal";
    }
    normalized: str = call_id;
    if not call_id.startswith("call_") {
        normalized = "call_" + call_id;
    }
    event = TurnEvent(
        event_id=stream_id + ":" + normalized + ":cancel",
        kind="tool.cancel",
        text="provider tool canceled",
        call_id=normalized
    );
    turn +>:Emits:+> event;
    return "tool_canceled";
}

def pause_turn(conn: Connection, stream_id: str) -> str {
    w: ActiveTurnWalker = conn spawn ActiveTurnWalker(requested_id=stream_id);
    if len(w.targets) == 0 {
        return "unknown_turn";
    }
    turn: Turn = w.targets[0];
    if turn.terminal {
        return "already_terminal";
    }
    turn.status = "paused";
    return "paused";
}

def resume_turn(conn: Connection, stream_id: str) -> str {
    w: ActiveTurnWalker = conn spawn ActiveTurnWalker(requested_id=stream_id);
    if len(w.targets) == 0 {
        return "unknown_turn";
    }
    turn: Turn = w.targets[0];
    if turn.terminal {
        return "already_terminal";
    }
    if turn.status != "paused" {
        return "not_paused";
    }
    turn.status = "running";
    return "resumed";
}

def turn_events(conn: Connection, stream_id: str) -> list[str] {
    w: ActiveTurnWalker = conn spawn ActiveTurnWalker(requested_id=stream_id);
    if len(w.targets) == 0 {
        return [];
    }
    turn: Turn = w.targets[0];
    trail: EventTrailWalker = turn spawn EventTrailWalker();
    return trail.events;
}

# TESTS
test "lifecycle_and_duplicate_replay" {
    conn = new_connection("c1");
    assert (hello(conn) == "hello:c1");
    assert (start_turn(conn, "s1", "request-a") == "started");
    assert (start_turn(conn, "s1", "request-a") == "attached");
    assert (start_turn(conn, "s1", "request-b") == "turn_conflict");
    assert (publish_event(conn, "s1", "e1", "provider.start", "ready") == "published");
    assert (publish_event(conn, "s1", "e2", "model.text", "hello") == "published");
    assert (publish_event(conn, "s1", "e3", "tool.call", "ok", "native-7") == "published");
    assert (publish_event(conn, "s1", "e4", "turn.end", "complete") == "published");
    assert (sorted(turn_events(conn, "s1")) == ["e1", "e2", "e3", "e4"]);
    assert (publish_event(conn, "s1", "e5", "model.text", "late") == "terminal");
}

test "connection_isolation_and_unknown_ids" {
    first = new_connection("first");
    second = new_connection("second");
    assert (start_turn(first, "same", "one") == "started");
    assert (start_turn(first, "other", "two") == "turn_already_active");
    assert (start_turn(second, "same", "two") == "started");
    assert (cancel_turn(first, "missing") == "unknown_turn");
    assert (turn_events(first, "missing") == []);
    assert (cancel_tool(second, "missing", "x") == "unknown_turn");
}

test "cancel_pause_resume_and_terminal_uniqueness" {
    conn = new_connection("c3");
    assert (start_turn(conn, "s3", "request") == "started");
    assert (pause_turn(conn, "s3") == "paused");
    assert (resume_turn(conn, "s3") == "resumed");
    assert (cancel_tool(conn, "s3", "native-2") == "tool_canceled");
    assert (cancel_turn(conn, "s3") == "canceled");
    assert (cancel_turn(conn, "s3") == "already_terminal");
    assert (publish_event(conn, "s3", "late-end", "turn.end", "duplicate") == "already_terminal");
    assert (sorted(turn_events(conn, "s3")) == ["s3:call_native-2:cancel", "s3:end"]);
}

test "diamond_revisit_is_claimed_once" {
    conn = new_connection("diamond");
    a = Turn(turn_stream_id="a", request="a");
    b = Turn(turn_stream_id="b", request="b");
    c = Turn(turn_stream_id="c", request="c");
    ea = TurnEvent(event_id="e-a", kind="model.text", text="a");
    eb = TurnEvent(event_id="e-b", kind="model.text", text="b");
    ec = TurnEvent(event_id="e-c", kind="model.text", text="c");
    conn +>:TurnOf:+> a;
    conn +>:TurnOf:+> b;
    a +>:Emits:+> ea;
    b +>:Emits:+> eb;
    c +>:Emits:+> ec;
    a +>:Link:+> b;
    a +>:Link:+> c;
    b +>:Link:+> c;
    c +>:Link:+> a;
    assert (sorted(turn_events(conn, "a")) == ["e-a", "e-b", "e-c"]);
}
