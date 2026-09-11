node PatchRoot { has name: str; }
node Mod {
    has mid: str;
    has frozen: bool = false;
    has raster_ver: int = 0;
    has field_ver: int = 0;
    has updated_at: int = 0;
    has last_sig: str = "";
}
edge Owns {}
edge Cable {}

walker ReachWalker {
    has target: str = "";
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can start with PatchRoot entry {
        for m in [here ->:Owns:->][?:Mod] {
            if m.mid == self.target {
                visit :0: [m];
            }
        }
        print("reach start " + here.name);
    }
    can step with Mod entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.found.append(here.mid);
        kids: list[Mod] = [here ->:Cable:->][?:Mod];
        if len(kids) == 0 {
            print("reach leaf " + here.mid);
            disengage;
        }
        for k in kids {
            visit :0: [k];
        }
        print("reach visit " + here.mid);
    }
}

walker LineageWalker {
    has target: str = "";
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can begin with PatchRoot entry {
        for m in [here ->:Owns:->][?:Mod] {
            if m.mid == self.target {
                visit :0: [m];
            }
        }
        print("lineage start " + here.name);
    }
    can walk_rev with Mod entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.found.append(here.mid);
        parents: list[Mod] = [here <-:Cable:->][?:Mod];
        if len(parents) == 0 {
            print("lineage root " + here.mid);
            disengage;
        }
        for p in parents {
            visit :0: [p];
        }
        print("lineage visit " + here.mid);
    }
}

walker RecentWalker {
    has since: int = 0;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can scan_root with PatchRoot entry {
        for m in [here ->:Owns:->][?:Mod] {
            visit :0: [m];
        }
        print("recent start " + here.name);
    }
    can scan_mod with Mod entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        if here.updated_at > self.since {
            self.found.append(here.mid);
        }
        print("recent visit " + here.mid);
        disengage;
    }
}

walker DirtyCollectWalker {
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];
    can collect_root with PatchRoot entry {
        for m in [here ->:Owns:->][?:Mod] {
            visit :0: [m];
        }
        print("dirty start " + here.name);
    }
    can collect_mod with Mod entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        if here.raster_ver > here.field_ver {
            self.collected.append(here.mid);
        }
        print("dirty check " + here.mid);
        disengage;
    }
}

def add_module(root_node: PatchRoot, mid: str, frozen: bool) -> Mod {
    nd = Mod(mid=mid, frozen=frozen);
    root_node +>:Owns:+> nd;
    return nd;
}

def connect_modules(a: Mod, b: Mod) {
    a +>:Cable:+> b;
}

def get_reachable(root_node: PatchRoot, start_id: str) -> list[str] {
    w = root_node spawn ReachWalker(target=start_id);
    return sorted(w.found);
}

def get_lineage(root_node: PatchRoot, target_id: str) -> list[str] {
    w = root_node spawn LineageWalker(target=target_id);
    return sorted(w.found);
}

def mark_raster(root_node: PatchRoot, mid: str, sig: str, ts: int) -> bool {
    for m in [root_node ->:Owns:->][?:Mod] {
        if m.mid == mid {
            if m.last_sig == sig {
                return False;
            }
            m.last_sig = sig;
            m.raster_ver = m.raster_ver + 1;
            m.updated_at = ts;
            return True;
        }
    }
    return False;
}

def rebuild_dirty_fields(root_node: PatchRoot) -> list[str] {
    w = root_node spawn DirtyCollectWalker();
    rebuilt: list[str] = [];
    for m in [root_node ->:Owns:->][?:Mod] {
        for cid in w.collected {
            if m.mid == cid {
                if m.raster_ver > m.field_ver {
                    m.field_ver = m.raster_ver;
                    rebuilt.append(m.mid);
                }
            }
        }
    }
    return sorted(rebuilt);
}

def recent_updates(root_node: PatchRoot, since: int) -> list[str] {
    w = root_node spawn RecentWalker(since=since);
    return sorted(w.found);
}

with entry {
    demo_root = PatchRoot(name="demo");
    a = add_module(demo_root, "foxy", false);
    b = add_module(demo_root, "face", false);
    connect_modules(a, b);
    w = demo_root spawn ReachWalker(target="foxy");
    print("demo reachable " + str(w.found));
}

test "diamond revisit reachability adversarial order" {
    r = PatchRoot(name="r");
    a = add_module(r, "a", false);
    b = add_module(r, "b", false);
    c = add_module(r, "c", false);
    d = add_module(r, "d", false);
    connect_modules(a, b);
    connect_modules(a, c);
    connect_modules(b, d);
    connect_modules(c, d);
    got = get_reachable(r, "a");
    assert(sorted(got) == ["a", "b", "c", "d"]);
    # second order: insert c before b still same closure
    r2 = PatchRoot(name="r2");
    a2 = add_module(r2, "a", false);
    c2 = add_module(r2, "c", false);
    b2 = add_module(r2, "b", false);
    d2 = add_module(r2, "d", false);
    connect_modules(a2, c2);
    connect_modules(a2, b2);
    connect_modules(c2, d2);
    connect_modules(b2, d2);
    got2 = get_reachable(r2, "a");
    assert(sorted(got2) == ["a", "b", "c", "d"]);
}

test "cycle and unknown id tolerance" {
    r = PatchRoot(name="r");
    x = add_module(r, "x", false);
    y = add_module(r, "y", false);
    z = add_module(r, "z", false);
    connect_modules(x, y);
    connect_modules(y, z);
    connect_modules(z, x);
    cyc = get_reachable(r, "x");
    assert(sorted(cyc) == ["x", "y", "z"]);
    empty = get_reachable(r, "nope");
    assert(empty == []);
    lin_empty = get_lineage(r, "nope");
    assert(lin_empty == []);
    mark = mark_raster(r, "nope", "sig", 10);
    assert(mark == False);
}

test "lineage reverse diamond" {
    r = PatchRoot(name="r");
    a = add_module(r, "a", false);
    b = add_module(r, "b", false);
    c = add_module(r, "c", false);
    d = add_module(r, "d", false);
    connect_modules(a, d);
    connect_modules(b, d);
    connect_modules(d, c);
    lin = get_lineage(r, "c");
    assert(sorted(lin) == ["a", "b", "c", "d"]);
    lin2 = get_lineage(r, "d");
    assert(sorted(lin2) == ["a", "b", "d"]);
}

test "dirty tracking skips unchanged raster" {
    r = PatchRoot(name="r");
    f = add_module(r, "foxy", false);
    g = add_module(r, "other", false);
    ch1 = mark_raster(r, "foxy", "sigA", 1);
    assert(ch1 == True);
    ch_dup = mark_raster(r, "foxy", "sigA", 2);
    assert(ch_dup == False);
    first = rebuild_dirty_fields(r);
    assert(first == ["foxy"]);
    second = rebuild_dirty_fields(r);
    assert(second == []);
    ch2 = mark_raster(r, "foxy", "sigB", 3);
    assert(ch2 == True);
    third = rebuild_dirty_fields(r);
    assert(third == ["foxy"]);
    # other never dirtied so never rebuilt
    assert("other" not in third);
}

test "recent updates filtering" {
    r = PatchRoot(name="r");
    a = add_module(r, "a", false);
    b = add_module(r, "b", false);
    c = add_module(r, "c", false);
    mark_raster(r, "a", "s1", 5);
    mark_raster(r, "b", "s2", 15);
    # c stays at 0
    rec10 = recent_updates(r, 10);
    assert(rec10 == ["b"]);
    rec0 = recent_updates(r, 0);
    assert(sorted(rec0) == ["a", "b"]);
    rec20: list[str] = recent_updates(r, 20);
    assert(rec20 == []);
}
