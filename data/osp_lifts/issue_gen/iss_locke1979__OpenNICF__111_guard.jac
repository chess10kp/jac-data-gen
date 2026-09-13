node Blob {
    has bid: str;
    has exp_size: int = 0;
    has exp_sha: str = "";
    has validated: bool = False;
    has isolated_part: bool = False;
}
node Proc {
    has pid: str;
    has alive: bool = True;
}
node Session {
    has sid: str;
    has checkpoint_count: int = 0;
    has interrupted: bool = False;
    has cleaned: bool = False;
}
edge Depends {}
edge Owns {}
edge Contains {}
walker CollectValidated {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can start with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        print("collect-validated");
        for nd in [here ->:Contains:->][?:Blob] { visit :0: [nd]; }
    }
    can step with Blob entry {
        if here.bid in self.claimed { skip; }
        self.claimed[here.bid] = True;
        if here.validated { self.out.append(here.bid); }
        for ch in [here ->:Depends:->][?:Blob] { visit :0: [ch]; }
    }
}
walker CollectPending {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can start_p with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        print("collect-pending");
        for nd in [here ->:Contains:->][?:Blob] { visit :0: [nd]; }
    }
    can step_p with Blob entry {
        if here.bid in self.claimed { skip; }
        self.claimed[here.bid] = True;
        if not here.validated and not here.isolated_part { self.out.append(here.bid); }
        for ch in [here ->:Depends:->][?:Blob] { visit :0: [ch]; }
    }
}
walker ReapWalker {
    has claimed: dict[str, bool] = {};
    has procs: list[Proc] = [];
    can start_r with Session entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        print("reap");
        for nd in [here ->:Contains:->][?:Proc] { visit :0: [nd]; }
    }
    can step_r with Proc entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.procs.append(here);
        for ch in [here ->:Owns:->][?:Proc] { visit :0: [ch]; }
    }
}
def create_session(sid: str) -> Session {
    s = Session(sid=sid);
    root ++> s;
    return s;
}
def register_blob(sess: Session, bid: str, exp_size: int, exp_sha: str) -> bool {
    for b in [sess ->:Contains:->][?:Blob] { if b.bid == bid { return False; } }
    nd = Blob(bid=bid, exp_size=exp_size, exp_sha=exp_sha);
    sess +>:Contains:+> nd;
    return True;
}
def add_dependency(sess: Session, from_bid: str, to_bid: str) -> bool {
    fb: Blob | None = None;
    tb: Blob | None = None;
    for b in [sess ->:Contains:->][?:Blob] {
        if b.bid == from_bid { fb = b; }
        if b.bid == to_bid { tb = b; }
    }
    if fb is None or tb is None { return False; }
    f: Blob = fb; t: Blob = tb;
    f +>:Depends:+> t;
    return True;
}
def validate_and_checkpoint(sess: Session, bid: str, actual_size: int, actual_sha: str) -> bool {
    found: Blob | None = None;
    for b in [sess ->:Contains:->][?:Blob] { if b.bid == bid { found = b; break; } }
    if found is None { return False; }
    fb: Blob = found;
    if fb.validated { return True; }
    if actual_size == fb.exp_size and actual_sha == fb.exp_sha and actual_size > 0 {
        fb.validated = True;
        fb.isolated_part = False;
        sess.checkpoint_count += 1;
        return True;
    }
    fb.isolated_part = True;
    return False;
}
def get_validated(sess: Session) -> list[str] {
    w = sess spawn CollectValidated(claimed={}, out=[]);
    return sorted(w.out);
}
def get_pending(sess: Session) -> list[str] {
    w = sess spawn CollectPending(claimed={}, out=[]);
    return sorted(w.out);
}
def add_process(sess: Session, pid: str, parent_pid: str | None = None) -> bool {
    for p in [sess ->:Contains:->][?:Proc] { if p.pid == pid { return False; } }
    nd = Proc(pid=pid, alive=True);
    if parent_pid is None {
        sess +>:Contains:+> nd;
        return True;
    }
    parent: Proc | None = None;
    for p in [sess ->:Contains:->][?:Proc] { if p.pid == parent_pid { parent = p; break; } }
    if parent is None { return False; }
    pr: Proc = parent;
    sess +>:Contains:+> nd;
    pr +>:Owns:+> nd;
    return True;
}
def has_owned_descendants(sess: Session) -> bool {
    w = sess spawn ReapWalker(claimed={}, procs=[]);
    for p in w.procs { if p.alive { return True; } }
    return False;
}
def interrupt_reconstruction(sess: Session) -> bool {
    w = sess spawn ReapWalker(claimed={}, procs=[]);
    for p in w.procs { p.alive = False; }
    sess.interrupted = True;
    sess.cleaned = True;
    for p in w.procs { if p.alive { return False; } }
    return True;
}
def audit_lifecycle(sess: Session) -> dict[str, bool] {
    d: dict[str, bool] = {};
    d["interrupted"] = sess.interrupted;
    d["cleaned"] = sess.cleaned;
    d["no_owned_descendants"] = not has_owned_descendants(sess);
    d["checkpointed"] = sess.checkpoint_count > 0;
    return d;
}
with entry {
    s = create_session("demo");
    register_blob(s, "b1", 10, "abc");
    validate_and_checkpoint(s, "b1", 10, "abc");
    w = s spawn CollectValidated(claimed={}, out=[]);
    print(str(w.out));
}

test "blob_close_ordering_diamond_does_not_duplicate" {
    s = create_session("t-diamond");
    assert(register_blob(s, "a", 10, "sa") == True);
    assert(register_blob(s, "b", 10, "sb") == True);
    assert(register_blob(s, "c", 10, "sc") == True);
    assert(register_blob(s, "d", 10, "sd") == True);
    assert(add_dependency(s, "a", "b") == True);
    assert(add_dependency(s, "a", "c") == True);
    assert(add_dependency(s, "b", "d") == True);
    assert(add_dependency(s, "c", "d") == True);
    for bid in ["a", "b", "c", "d"] { assert(validate_and_checkpoint(s, bid, 10, "s" + bid) == True); }
    v = get_validated(s);
    assert(len(v) == 4);
    assert(v == ["a", "b", "c", "d"]);
}
test "unknown_id_tolerance" {
    s = create_session("t-unknown");
    register_blob(s, "x", 10, "sx");
    assert(validate_and_checkpoint(s, "nope", 10, "sx") == False);
    assert(get_validated(s) == []);
    assert(add_dependency(s, "x", "missing") == False);
    assert(add_process(s, "p1", "missing-parent") == False);
    assert(validate_and_checkpoint(s, "x", 99, "wrong") == False);
    assert(len(get_validated(s)) == 0);
}
test "interrupt_leaves_no_owned_descendants" {
    s = create_session("t-intr");
    assert(add_process(s, "sup") == True);
    assert(add_process(s, "curl1", "sup") == True);
    assert(add_process(s, "curl2", "sup") == True);
    assert(has_owned_descendants(s) == True);
    assert(interrupt_reconstruction(s) == True);
    assert(has_owned_descendants(s) == False);
    a = audit_lifecycle(s);
    assert(a["interrupted"] == True);
    assert(a["cleaned"] == True);
    assert(a["no_owned_descendants"] == True);
}
test "checkpoint_and_resume_preserves_validated" {
    s = create_session("t-resume");
    for i in [1, 2, 3, 4, 5] {
        bid = "k" + str(i);
        register_blob(s, bid, 10, "s" + bid);
    }
    assert(validate_and_checkpoint(s, "k1", 10, "sk1") == True);
    assert(validate_and_checkpoint(s, "k2", 10, "sk2") == True);
    assert(s.checkpoint_count == 2);
    p = get_pending(s);
    assert("k1" not in p);
    assert("k2" not in p);
    assert(len(p) == 3);
    assert(get_validated(s) == ["k1", "k2"]);
    assert(validate_and_checkpoint(s, "k1", 10, "sk1") == True);
    assert(s.checkpoint_count == 2);
}
test "size_sha_validation_isolates_part" {
    s = create_session("t-isolate");
    register_blob(s, "good", 10, "sg");
    register_blob(s, "bad", 10, "sb");
    assert(validate_and_checkpoint(s, "good", 10, "sg") == True);
    assert(validate_and_checkpoint(s, "bad", 5, "sb") == False);
    assert(get_validated(s) == ["good"]);
    assert(len(get_pending(s)) == 0);
}
