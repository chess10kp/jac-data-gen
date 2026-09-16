"""mikeev261/HidHide#12 — PID-to-image BST lift (recursive tree + boot self-test)."""

node PidNode {
    has pid: int;
    has image: str;
    has live: bool = True;
}

node CacheSlot {
    has slot_id: str;
    has fresh: bool = True;
}

edge Left {}
edge Right {}
edge Aux {}
edge Invalidates {}

walker InsertWalk {
    has pid: int;
    has image: str;
    has placed: bool = False;
    has updated: bool = False;
    has touch_node: PidNode | None = None;
    has claimed: dict[int, bool] = {};

    can descend with PidNode entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        if not here.live { disengage; }
        if here.pid == self.pid {
            here.image = self.image;
            self.updated = True;
            self.placed = True;
            self.touch_node = here;
            disengage;
        }
        if self.pid < here.pid {
            kids: list[PidNode] = [here ->:Left:->][?:PidNode];
            if kids { visit :0: [kids[0]]; }
            else {
                child = PidNode(pid=self.pid, image=self.image);
                here +>:Left:+> child;
                self.placed = True;
                disengage;
            }
        } else {
            kids: list[PidNode] = [here ->:Right:->][?:PidNode];
            if kids { visit :0: [kids[0]]; }
            else {
                child = PidNode(pid=self.pid, image=self.image);
                here +>:Right:+> child;
                self.placed = True;
                disengage;
            }
        }
    }
}

walker LookupWalk {
    has target: int;
    has found: str = "";
    has hit: bool = False;
    has claimed: dict[int, bool] = {};

    can seek with PidNode entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        if not here.live { disengage; }
        if here.pid == self.target {
            self.found = here.image;
            self.hit = True;
            disengage;
        }
        if self.target < here.pid {
            kids: list[PidNode] = [here ->:Left:->][?:PidNode];
            if kids { visit :0: [kids[0]]; } else { disengage; }
        } else {
            kids: list[PidNode] = [here ->:Right:->][?:PidNode];
            if kids { visit :0: [kids[0]]; } else { disengage; }
        }
    }
}

walker RemoveSeekWalk {
    has target: int;
    has hit: bool = False;
    has found_node: PidNode | None = None;
    has claimed: dict[int, bool] = {};

    can seek with PidNode entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        if not here.live { disengage; }
        if here.pid == self.target {
            self.hit = True;
            self.found_node = here;
            disengage;
        }
        if self.target < here.pid {
            kids: list[PidNode] = [here ->:Left:->][?:PidNode];
            if kids { visit :0: [kids[0]]; } else { disengage; }
        } else {
            kids: list[PidNode] = [here ->:Right:->][?:PidNode];
            if kids { visit :0: [kids[0]]; } else { disengage; }
        }
    }
}

walker InvalidateHereWalk {
    has count: int = 0;
    has claimed: dict[int, bool] = {};

    can sweep with PidNode entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        slots: list[CacheSlot] = [here ->:Invalidates:->][?:CacheSlot];
        for sl in slots {
            sl.fresh = False;
            self.count += 1;
        }
        disengage;
    }
}

walker SelfTestWalk {
    has ok: bool = True;
    has claimed: dict[int, bool] = {};

    can audit with PidNode entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        kids_l: list[PidNode] = [here ->:Left:->][?:PidNode];
        if kids_l {
            if kids_l[0].pid >= here.pid { self.ok = False; }
        }
        kids_r: list[PidNode] = [here ->:Right:->][?:PidNode];
        if kids_r {
            if kids_r[0].pid <= here.pid { self.ok = False; }
        }
        nxt: list[PidNode] = [];
        for k in kids_l { nxt.append(k); }
        for k in kids_r { nxt.append(k); }
        if nxt { visit :0: nxt; } else { disengage; }
    }
}

walker CollectPidWalk {
    has seen_count: int = 0;
    has claimed: dict[int, bool] = {};

    can step with PidNode entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.seen_count += 1;
        kids: list[PidNode] = [];
        kl: list[PidNode] = [here ->:Left:->][?:PidNode];
        kr: list[PidNode] = [here ->:Right:->][?:PidNode];
        ka: list[PidNode] = [here ->:Aux:->][?:PidNode];
        for k in kl { kids.append(k); }
        for k in kr { kids.append(k); }
        for k in ka { kids.append(k); }
        if kids { visit :0: kids; } else { disengage; }
    }
}

def make_store -> PidNode | None {
    return None;
}

def store_insert(tree_root: PidNode | None, pid: int, image: str) -> PidNode {
    if tree_root is None {
        nd = PidNode(pid=pid, image=image);
        root ++> nd;
        print("insert_root", pid);
        return nd;
    }
    w = tree_root spawn InsertWalk(pid=pid, image=image, claimed={});
    if w.updated {
        inv = w.touch_node spawn InvalidateHereWalk(claimed={});
        print("insert_reuse", pid, inv.count);
    } else {
        print("insert_ok", pid);
    }
    return tree_root;
}

def store_lookup(tree_root: PidNode | None, pid: int) -> str | None {
    if tree_root is None { return None; }
    w = tree_root spawn LookupWalk(target=pid, claimed={});
    print("lookup", pid, w.hit);
    if w.hit { return w.found; }
    return None;
}

def store_remove(tree_root: PidNode | None, pid: int) -> bool {
    if tree_root is None { return False; }
    w = tree_root spawn RemoveSeekWalk(target=pid, claimed={});
    if not w.hit {
        print("remove_miss", pid);
        return False;
    }
    w.found_node.live = False;
    inv = w.found_node spawn InvalidateHereWalk(claimed={});
    print("remove_ok", pid, inv.count);
    return True;
}

def store_boot_self_test(tree_root: PidNode | None) -> bool {
    if tree_root is None { return True; }
    w = tree_root spawn SelfTestWalk(claimed={});
    print("self_test", w.ok);
    return w.ok;
}

def store_live_count(tree_root: PidNode | None) -> int {
    if tree_root is None { return 0; }
    w = tree_root spawn CollectPidWalk(claimed={});
    print("live_count", w.seen_count);
    return w.seen_count;
}
