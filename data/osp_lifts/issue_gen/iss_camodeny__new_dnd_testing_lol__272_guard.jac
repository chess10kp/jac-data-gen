# PROGRAM iss_camodeny__new_dnd_testing_lol__272.jac

node Campaign {
    has total: int = 0;
    has checkpoint: int = 0;
    has safe_lag: int = 2;
    has clock: int = 0;
    has current_truth: str = "unknown";
    has embedding_epoch: int = 0;
    has projection_epoch: int = 0;
    has secret_visible: bool = False;
}

node Event {
    has seq: int;
    has payload: str;
    has applied: bool = False;
}

node Record {
    has key: str;
    has value: str;
    has valid: bool = True;
    has private: bool = False;
    has repaired: bool = False;
}

node Repair {
    has key: str;
    has replacement: str;
    has retcon: bool = False;
    has private: bool = False;
    has applied: bool = False;
}

edge Starts {}
edge Next {}
edge Affects {}
edge DependsOn {}
edge HasRepair {}

walker CatchUp {
    has claimed: dict[str, bool] = {};
    has start_seq: int = 0;
    has end_seq: int = 0;
    has fail_at: int = -1;
    has pending: list[Event] = [];

    can step_campaign with Campaign entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for event in [here ->:Starts:->][?:Event] {
            visit :0: [event];
        }
        print("catch-up campaign");
    }

    can step_event with Event entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.seq >= self.start_seq {
            if here.seq <= self.end_seq {
                if self.fail_at < 0 {
                    if here.applied == False { self.pending.append(here); }
                } else {
                    if here.seq < self.fail_at {
                        if here.applied == False { self.pending.append(here); }
                    }
                }
            }
        }
        for next_event in [here ->:Next:->][?:Event] {
            visit :0: [next_event];
        }
        print("catch-up event");
    }
}

walker Inspect {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: Record | None = None;
    has invalid: list[Record] = [];
    has repairs: list[Repair] = [];
    has records_seen: int = 0;

    can inspect_campaign with Campaign entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for event in [here ->:Starts:->][?:Event] {
            visit :0: [event];
        }
        print("inspect campaign");
    }

    can inspect_event with Event entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for record in [here ->:Affects:->][?:Record] {
            visit :0: [record];
        }
        for repair in [here ->:HasRepair:->][?:Repair] {
            visit :0: [repair];
        }
        for next_event in [here ->:Next:->][?:Event] {
            visit :0: [next_event];
        }
        print("inspect event");
    }

    can inspect_record with Record entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.records_seen += 1;
        if here.key == self.target { self.found = here; }
        if here.valid == False { self.invalid.append(here); }
        for dependency in [here ->:DependsOn:->][?:Record] {
            visit :0: [dependency];
        }
        print("inspect record");
    }

    can inspect_repair with Repair entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.applied == False { self.repairs.append(here); }
        print("inspect repair");
    }
}

def build_alpha_graph() -> Campaign {
    root_node = Campaign(total=5, safe_lag=2);
    e1 = Event(seq=1, payload="turn-one");
    e2 = Event(seq=2, payload="turn-two");
    e3 = Event(seq=3, payload="contradiction");
    e4 = Event(seq=4, payload="retcon");
    e5 = Event(seq=5, payload="hidden-consequence");
    ra = Record(key="identity", value="old", valid=False);
    rb = Record(key="claim", value="npc");
    rc = Record(key="clock", value="stale");
    rd = Record(key="summary", value="derived");
    fix1 = Repair(key="identity", replacement="canon", retcon=True);
    fix2 = Repair(key="secret", replacement="secret", retcon=True, private=True);

    root_node +>:Starts:+> e1;
    e1 +>:Next:+> e2;
    e2 +>:Next:+> e3;
    e3 +>:Next:+> e4;
    e4 +>:Next:+> e5;
    e3 +>:Affects:+> ra;
    e4 +>:Affects:+> rb;
    e5 +>:Affects:+> rc;
    ra +>:DependsOn:+> rb;
    ra +>:DependsOn:+> rc;
    rb +>:DependsOn:+> rd;
    rc +>:DependsOn:+> rd;
    rd +>:DependsOn:+> rb;
    e4 +>:HasRepair:+> fix1;
    e5 +>:HasRepair:+> fix2;
    return root_node;
}

def process_backlog(root_node: Campaign, fail_at: int = -1) -> dict[str, int] {
    start_seq: int = root_node.checkpoint + 1;
    w = root_node spawn CatchUp(
        start_seq=start_seq,
        end_seq=root_node.total,
        fail_at=fail_at,
        claimed={}
    );
    for event in w.pending {
        event.applied = True;
    }
    root_node.checkpoint += len(w.pending);
    root_node.clock += len(w.pending);
    result: dict[str, int] = {};
    result["applied"] = len(w.pending);
    result["checkpoint"] = root_node.checkpoint;
    result["failed"] = 0;
    if fail_at >= start_seq {
        if fail_at <= root_node.total { result["failed"] = 1; }
    }
    return result;
}

def repair_current(root_node: Campaign) -> dict[str, int] {
    w = root_node spawn Inspect(claimed={});
    for record in w.invalid {
        record.valid = True;
        record.repaired = True;
    }
    for repair in w.repairs {
        repair.applied = True;
        if repair.private == False { root_node.current_truth = repair.replacement; }
        if repair.retcon { root_node.embedding_epoch += 1; }
    }
    root_node.projection_epoch += len(w.invalid);
    result: dict[str, int] = {};
    result["repaired"] = len(w.invalid);
    result["repairs"] = len(w.repairs);
    result["records_seen"] = w.records_seen;
    return result;
}

def find_record(root_node: Campaign, key: str) -> Record | None {
    w = root_node spawn Inspect(target=key, claimed={});
    return w.found;
}

def can_progress(root_node: Campaign) -> bool {
    return root_node.total - root_node.checkpoint <= root_node.safe_lag;
}

# TESTS

test "cumulative catch-up after failure" {
    g = build_alpha_graph();
    first = process_backlog(g, 3);
    assert (first["checkpoint"] == 2);
    assert (first["failed"] == 1);
    assert (can_progress(g) == False);
    second = process_backlog(g);
    assert (second["checkpoint"] == 5);
    assert (second["applied"] == 3);
    retry = process_backlog(g);
    assert (retry["applied"] == 0);
    assert (can_progress(g) == True);
}

test "diamond revisit is claimed once" {
    g = build_alpha_graph();
    process_backlog(g);
    stats = repair_current(g);
    assert (stats["records_seen"] == 4);
    assert (stats["repaired"] == 1);
    assert (stats["repairs"] == 2);
}

test "unknown record is tolerated" {
    g = build_alpha_graph();
    missing = find_record(g, "missing");
    assert (missing == None);
    known = find_record(g, "identity");
    assert (known != None);
}

test "private repair does not broaden visibility" {
    g = build_alpha_graph();
    process_backlog(g);
    repair_current(g);
    assert (g.current_truth == "canon");
    assert (g.secret_visible == False);
    assert (g.embedding_epoch == 2);
    again = repair_current(g);
    assert (again["repairs"] == 0);
}
