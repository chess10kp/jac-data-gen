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
