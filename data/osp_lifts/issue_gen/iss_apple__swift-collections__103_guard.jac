"""Stable ordered collection with stable indices — apple/swift-collections#103."""

node StableStore {
    has next_sid: int = 1;
    has tail_cid: str = "";
}

node Entry {
    has sid: int;
    has value: str;
    has alive: bool = True;
}

edge Head {}
edge Succ {}

walker AppendLink {
    has new_ent: Entry;
    has claimed: dict[str, bool] = {};

    can begin with StableStore entry {
        print ["AppendLink", self.new_ent.sid];
        heads: list[Entry] = [here ->:Head:->][?:Entry];
        if not heads {
            here +>:Head:+> self.new_ent;
            here.tail_cid = self.new_ent.cid;
            disengage;
        }
        tail_seek = heads[0] spawn TailSeek(new_ent=self.new_ent, claimed={});
        here.tail_cid = tail_seek.last_cid;
        disengage;
    }
}

walker TailSeek {
    has new_ent: Entry;
    has claimed: dict[str, bool] = {};
    has last_cid: str = "";

    can hop with Entry entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.last_cid = here.cid;
        nxts: list[Entry] = [here ->:Succ:->][?:Entry];
        if nxts {
            visit :0: [nxts[0]];
        } else {
            here +>:Succ:+> self.new_ent;
            self.last_cid = self.new_ent.cid;
            print ["TailSeek", here.cid, self.new_ent.cid];
        }
    }
}

walker FindSid {
    has target: int = 0;
    has found: str | None = None;
    has claimed: dict[str, bool] = {};

    can scan_store with StableStore entry {
        print ["FindSid", self.target];
        kids: list[Entry] = [here ->>][?:Entry];
        for kid in kids {
            visit :0: [kid];
        }
    }

    can scan_entry with Entry entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.sid == self.target and here.alive {
            self.found = here.value;
            disengage;
        }
    }
}

walker CollectOrder {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];

    can begin with StableStore entry {
        print ["CollectOrder", here.cid];
        heads: list[Entry] = [here ->:Head:->][?:Entry];
        if heads {
            visit :0: [heads[0]];
        } else {
            disengage;
        }
    }

    can step with Entry entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.alive {
            self.out.append(here.value);
        }
        nxts: list[Entry] = [here ->:Succ:->][?:Entry];
        for nxt in nxts {
            visit :0: [nxt];
        }
    }
}

walker DistWalk {
    has sid_a: int = 0;
    has sid_b: int = 0;
    has dist: int | None = None;
    has seen_a: bool = False;
    has steps: int = 0;
    has claimed: dict[str, bool] = {};

    can begin with StableStore entry {
        print ["DistWalk", self.sid_a, self.sid_b];
        heads: list[Entry] = [here ->:Head:->][?:Entry];
        if heads {
            visit :0: [heads[0]];
        } else {
            disengage;
        }
    }

    can step with Entry entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.alive {
            if here.sid == self.sid_b {
                if self.seen_a {
                    self.dist = self.steps;
                }
                disengage;
            }
            if here.sid == self.sid_a {
                self.seen_a = True;
            }
            if self.seen_a {
                self.steps = self.steps + 1;
            }
        }
        nxts: list[Entry] = [here ->:Succ:->][?:Entry];
        for nxt in nxts {
            visit :0: [nxt];
        }
    }
}

def make_stable_array -> StableStore {
    arr = StableStore();
    root ++> arr;
    return arr;
}

def append_value(arr: StableStore, value: str) -> int {
    sid = arr.next_sid;
    arr.next_sid = sid + 1;
    ent = Entry(sid=sid, value=value);
    root ++> ent;
    arr ++> ent;
    arr spawn AppendLink(new_ent=ent);
    print ["append_value", sid, value];
    return sid;
}

def remove_at(arr: StableStore, sid: int) -> bool {
    w = arr spawn FindSid(target=sid);
    if not w.found {
        print ["remove_at", sid, False];
        return False;
    }
    kids: list[Entry] = [arr ->>][?:Entry];
    for kid in kids {
        if kid.sid == sid {
            kid.alive = False;
            print ["remove_at", sid, True];
            return True;
        }
    }
    print ["remove_at", sid, False];
    return False;
}

def get_at(arr: StableStore, sid: int) -> str | None {
    w = arr spawn FindSid(target=sid);
    print ["get_at", sid, w.found];
    return w.found;
}

def ordered_values(arr: StableStore) -> list[str] {
    w = arr spawn CollectOrder();
    print ["ordered_values", len(w.out)];
    return w.out;
}

def first_index_of(arr: StableStore, value: str) -> int | None {
    kids: list[Entry] = [arr ->>][?:Entry];
    best: int | None = None;
    for kid in kids {
        if kid.alive and kid.value == value {
            if not best {
                best = kid.sid;
            } elif kid.sid < best {
                best = kid.sid;
            }
        }
    }
    print ["first_index_of", value, best];
    return best;
}

def index_distance(arr: StableStore, sid_a: int, sid_b: int) -> int | None {
    w = arr spawn DistWalk(sid_a=sid_a, sid_b=sid_b);
    print ["index_distance", sid_a, sid_b, w.dist];
    return w.dist;
}

test "append_and_order" {
    arr = make_stable_array();
    s0 = append_value(arr, "a");
    s1 = append_value(arr, "b");
    s2 = append_value(arr, "c");
    out = ordered_values(arr);
    assert len(out) == 3;
    assert out[0] == "a";
    assert out[1] == "b";
    assert out[2] == "c";
}

test "stable_indices_after_remove" {
    arr = make_stable_array();
    s0 = append_value(arr, "a");
    s1 = append_value(arr, "b");
    s2 = append_value(arr, "c");
    ok = remove_at(arr, s1);
    assert ok == True;
    assert get_at(arr, s0) == "a";
    assert get_at(arr, s1) == None;
    assert get_at(arr, s2) == "c";
    out = ordered_values(arr);
    assert len(out) == 2;
    assert out[0] == "a";
    assert out[1] == "c";
}

test "first_index_of_lowest_sid" {
    arr = make_stable_array();
    s0 = append_value(arr, "x");
    s1 = append_value(arr, "y");
    s2 = append_value(arr, "x");
    idx = first_index_of(arr, "x");
    assert idx == s0;
    assert idx != s2;
    assert first_index_of(arr, "missing") == None;
}

test "index_distance_alive_chain" {
    arr = make_stable_array();
    s0 = append_value(arr, "a");
    s1 = append_value(arr, "b");
    s2 = append_value(arr, "c");
    d01 = index_distance(arr, s0, s1);
    d02 = index_distance(arr, s0, s2);
    assert d01 == 1;
    assert d02 == 2;
}

test "remove_missing_returns_false" {
    arr = make_stable_array();
    s0 = append_value(arr, "only");
    ok = remove_at(arr, s0);
    assert ok == True;
    miss = remove_at(arr, s0);
    assert miss == False;
    assert get_at(arr, s0) == None;
}

test "distance_skips_removed" {
    arr = make_stable_array();
    s0 = append_value(arr, "a");
    s1 = append_value(arr, "b");
    s2 = append_value(arr, "c");
    remove_at(arr, s1);
    d = index_distance(arr, s0, s2);
    assert d == 1;
}
