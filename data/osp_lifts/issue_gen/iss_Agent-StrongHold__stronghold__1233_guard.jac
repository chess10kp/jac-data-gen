"""Agent-StrongHold/stronghold#1233 — relation-hop reachability & supersession cascade."""

node Fact {
    has cid: str;
    has episode_id: str;
    has active: bool = True;
}

edge Relates {}
edge Superseded {}

walker IndexWalker {
    has idx: dict[str, Fact] = {};
    has claimed: dict[str, bool] = {};

    can walk_root with object entry {
        kids: list[Fact] = [here ->][?:Fact];
        for ch in kids {
            visit :0: [ch];
        }
    }

    can walk_fact with Fact entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.idx[here.cid] = here;
        print("index %s" % here.cid);
        kids: list[Fact] = [here ->][?:Fact];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has max_hops: int = 0;
    has origin: str = "";
    has found: list[str] = [];
    has cur_depth: int = 0;

    can step with Fact entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("reach %s %s" % (here.cid, self.cur_depth));
        if here.cid != self.origin {
            self.found.append(here.cid);
        }
        if self.cur_depth >= self.max_hops {
            disengage;
        }
        kids: list[Fact] = [here ->:Relates:->][?:Fact];
        for kid in kids {
            wk = kid spawn ReachWalker(
                claimed=self.claimed,
                max_hops=self.max_hops,
                origin=self.origin,
                found=self.found,
                cur_depth=self.cur_depth + 1
            );
        }
        if !kids {
            disengage;
        }
    }
}

walker CascadeWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Fact entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print("cascade %s" % here.cid);
        kids: list[Fact] = [here ->:Superseded:->][?:Fact];
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def memory_index() -> dict[str, Fact] {
    idx: dict[str, Fact] = {};
    w = root spawn IndexWalker(idx=idx);
    return w.idx;
}

def reachable_relation_ids(start_id: str, max_hops: int) -> list[str] {
    idx = memory_index();
    if start_id not in idx {
        return [];
    }
    start_fact = idx[start_id];
    found: list[str] = [];
    claimed: dict[str, bool] = {};
    w = start_fact spawn ReachWalker(
        claimed=claimed,
        max_hops=max_hops,
        origin=start_id,
        found=found,
        cur_depth=0
    );
    out: list[str] = sorted(found);
    print("reachable %s" % out);
    return out;
}

def cascade_superseded_ids(start_id: str) -> list[str] {
    idx = memory_index();
    if start_id not in idx {
        return [];
    }
    start_fact = idx[start_id];
    found: list[str] = [];
    claimed: dict[str, bool] = {};
    w = start_fact spawn CascadeWalker(claimed=claimed, found=found);
    out: list[str] = sorted(found);
    print("cascade_out %s" % out);
    return out;
}

def seed_diamond_graph {
    a = Fact(cid="a", episode_id="e1");
    root ++> a;
    b = Fact(cid="b", episode_id="e1");
    root ++> b;
    c = Fact(cid="c", episode_id="e1");
    root ++> c;
    d = Fact(cid="d", episode_id="e1");
    root ++> d;
    b +>:Relates:+> d;
    c +>:Relates:+> d;
    a +>:Relates:+> c;
    a +>:Relates:+> b;
}

def seed_relation_cycle {
    x = Fact(cid="x", episode_id="e2");
    root ++> x;
    y = Fact(cid="y", episode_id="e2");
    root ++> y;
    z = Fact(cid="z", episode_id="e2");
    root ++> z;
    x +>:Relates:+> y;
    y +>:Relates:+> z;
    z +>:Relates:+> x;
}

def seed_supersession_chain {
    f1 = Fact(cid="f1", episode_id="s1");
    root ++> f1;
    f2 = Fact(cid="f2", episode_id="s1");
    root ++> f2;
    f3 = Fact(cid="f3", episode_id="s1");
    root ++> f3;
    f1 +>:Superseded:+> f2;
    f2 +>:Superseded:+> f3;
}

"""Agent-StrongHold/stronghold#1233 — relation-hop reachability & supersession cascade."""

node Fact {
    has cid: str;
    has episode_id: str;
    has active: bool = True;
}

edge Relates {}
edge Superseded {}

walker IndexWalker {
    has idx: dict[str, Fact] = {};
    has claimed: dict[str, bool] = {};

    can walk_root with object entry {
        kids: list[Fact] = [here ->][?:Fact];
        for ch in kids {
            visit :0: [ch];
        }
    }

    can walk_fact with Fact entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.idx[here.cid] = here;
        print("index %s" % here.cid);
        kids: list[Fact] = [here ->][?:Fact];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has max_hops: int = 0;
    has origin: str = "";
    has found: list[str] = [];
    has cur_depth: int = 0;

    can step with Fact entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("reach %s %s" % (here.cid, self.cur_depth));
        if here.cid != self.origin {
            self.found.append(here.cid);
        }
        if self.cur_depth >= self.max_hops {
            disengage;
        }
        kids: list[Fact] = [here ->:Relates:->][?:Fact];
        for kid in kids {
            wk = kid spawn ReachWalker(
                claimed=self.claimed,
                max_hops=self.max_hops,
                origin=self.origin,
                found=self.found,
                cur_depth=self.cur_depth + 1
            );
        }
        if !kids {
            disengage;
        }
    }
}

walker CascadeWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Fact entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print("cascade %s" % here.cid);
        kids: list[Fact] = [here ->:Superseded:->][?:Fact];
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def memory_index() -> dict[str, Fact] {
    idx: dict[str, Fact] = {};
    w = root spawn IndexWalker(idx=idx);
    return w.idx;
}

def reachable_relation_ids(start_id: str, max_hops: int) -> list[str] {
    idx = memory_index();
    if start_id not in idx {
        return [];
    }
    start_fact = idx[start_id];
    found: list[str] = [];
    claimed: dict[str, bool] = {};
    w = start_fact spawn ReachWalker(
        claimed=claimed,
        max_hops=max_hops,
        origin=start_id,
        found=found,
        cur_depth=0
    );
    out: list[str] = sorted(found);
    print("reachable %s" % out);
    return out;
}

def cascade_superseded_ids(start_id: str) -> list[str] {
    idx = memory_index();
    if start_id not in idx {
        return [];
    }
    start_fact = idx[start_id];
    found: list[str] = [];
    claimed: dict[str, bool] = {};
    w = start_fact spawn CascadeWalker(claimed=claimed, found=found);
    out: list[str] = sorted(found);
    print("cascade_out %s" % out);
    return out;
}

def seed_diamond_graph {
    a = Fact(cid="a", episode_id="e1");
    root ++> a;
    b = Fact(cid="b", episode_id="e1");
    root ++> b;
    c = Fact(cid="c", episode_id="e1");
    root ++> c;
    d = Fact(cid="d", episode_id="e1");
    root ++> d;
    b +>:Relates:+> d;
    c +>:Relates:+> d;
    a +>:Relates:+> c;
    a +>:Relates:+> b;
}

def seed_relation_cycle {
    x = Fact(cid="x", episode_id="e2");
    root ++> x;
    y = Fact(cid="y", episode_id="e2");
    root ++> y;
    z = Fact(cid="z", episode_id="e2");
    root ++> z;
    x +>:Relates:+> y;
    y +>:Relates:+> z;
    z +>:Relates:+> x;
}

def seed_supersession_chain {
    f1 = Fact(cid="f1", episode_id="s1");
    root ++> f1;
    f2 = Fact(cid="f2", episode_id="s1");
    root ++> f2;
    f3 = Fact(cid="f3", episode_id="s1");
    root ++> f3;
    f1 +>:Superseded:+> f2;
    f2 +>:Superseded:+> f3;
}

test "diamond_two_hop_reach" {
    seed_diamond_graph();
    out = reachable_relation_ids("a", 2);
    assert (out == ["b", "c", "d"]);;
}

test "diamond_zero_hop_excludes_origin" {
    seed_diamond_graph();
    out = reachable_relation_ids("a", 0);
    assert (out == []);;
}

test "cycle_claim_skip" {
    seed_relation_cycle();
    out = reachable_relation_ids("x", 5);
    assert (out == ["y", "z"]);;
}

test "supersession_cascade_chain" {
    seed_supersession_chain();
    out = cascade_superseded_ids("f1");
    assert (out == ["f1", "f2", "f3"]);;
}

test "unknown_start_empty_reach" {
    seed_diamond_graph();
    out = reachable_relation_ids("missing", 3);
    assert (out == []);;
}

test "memory_index_has_seeded_cids" {
    seed_diamond_graph();
    idx = memory_index();
    assert ("a" in idx);;
    assert ("d" in idx);;
}
