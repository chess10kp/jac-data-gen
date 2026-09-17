"""
PID-to-image mapping lift — mikeev261/HidHide#12.
Replaces bespoke recursive BST + boot self-test with OSP nodes/walkers.
"""

node PidNode {
    has pid: int;
    has image: str;
    has cid: str;
}

node PidRegistry {
    has cid: str = "pid-registry";
}

edge left {}
edge right {}
edge probe {}

def make_registry -> PidRegistry {
    let reg = PidRegistry();
    root ++> reg;
    return reg;
}

walker InsertFind {
    has target_pid: int;
    has parent: PidNode | None = None;
    has attach_left: bool = False;
    has needs_root: bool = False;
    has hit_existing: bool = False;
    has existing: PidNode | None = None;
    has claimed: dict[str, bool] = {};
    can step with PidNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("insert-find", here.pid);
        if here.pid == self.target_pid {
            self.hit_existing = True;
            self.existing = here;
            disengage;
        }
        self.parent = here;
        if self.target_pid < here.pid {
            self.attach_left = True;
            let ls: list[PidNode] = [here ->:left:->][?:PidNode];
            if len(ls) > 0 { visit :0: ls; } else { disengage; }
        } else {
            self.attach_left = False;
            let rs: list[PidNode] = [here ->:right:->][?:PidNode];
            if len(rs) > 0 { visit :0: rs; } else { disengage; }
        }
    }
    can begin with PidRegistry entry {
        print("insert-find registry");
        let roots: list[PidNode] = [here ->][?:PidNode];
        if len(roots) == 0 { self.needs_root = True; disengage; }
        else { visit :0: roots; }
    }
}

walker Lookup {
    has target_pid: int;
    has found: bool = False;
    has found_image: str = "";
    has claimed: dict[str, bool] = {};
    can step with PidNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("lookup", here.pid);
        if here.pid == self.target_pid {
            self.found = True;
            self.found_image = here.image;
            disengage;
        }
        if self.target_pid < here.pid {
            let ls: list[PidNode] = [here ->:left:->][?:PidNode];
            if len(ls) > 0 { visit :0: ls; } else { disengage; }
        } else {
            let rs: list[PidNode] = [here ->:right:->][?:PidNode];
            if len(rs) > 0 { visit :0: rs; } else { disengage; }
        }
    }
    can begin with PidRegistry entry {
        print("lookup registry");
        let roots: list[PidNode] = [here ->][?:PidNode];
        if len(roots) > 0 { visit :0: roots; } else { disengage; }
    }
}

walker Validate {
    has ok: bool = True;
    has claimed: dict[str, bool] = {};
    can step with PidNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("validate", here.pid);
        let ls: list[PidNode] = [here ->:left:->][?:PidNode];
        for ch in ls {
            if ch.pid >= here.pid { self.ok = False; }
            visit :0: [ch];
        }
        let rs: list[PidNode] = [here ->:right:->][?:PidNode];
        for ch in rs {
            if ch.pid <= here.pid { self.ok = False; }
            visit :0: [ch];
        }
    }
    can begin with PidRegistry entry {
        print("validate registry");
        let roots: list[PidNode] = [here ->][?:PidNode];
        for r in roots { visit :0: [r]; }
        disengage;
    }
}

walker CollectAll {
    has pids: list[int] = [];
    has claimed: dict[str, bool] = {};
    can step with PidNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("collect", here.pid);
        self.pids.append(here.pid);
        let ls: list[PidNode] = [here ->:left:->][?:PidNode];
        for ch in ls { visit :0: [ch]; }
        let rs: list[PidNode] = [here ->:right:->][?:PidNode];
        for ch in rs { visit [ch]; }
        let ps: list[PidNode] = [here ->:probe:->][?:PidNode];
        for ch in ps { visit [ch]; }
    }
    can begin with PidRegistry entry {
        print("collect registry");
        let roots: list[PidNode] = [here ->][?:PidNode];
        for r in roots { visit :0: [r]; }
        disengage;
    }
}

walker RemoveFind {
    has target_pid: int;
    has victim: PidNode | None = None;
    has parent: PidNode | None = None;
    has victim_is_left: bool = False;
    has claimed: dict[str, bool] = {};
    can step with PidNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("remove-find", here.pid);
        if here.pid == self.target_pid {
            self.victim = here;
            disengage;
        }
        if self.target_pid < here.pid {
            let ls: list[PidNode] = [here ->:left:->][?:PidNode];
            if len(ls) > 0 {
                self.parent = here;
                self.victim_is_left = True;
                visit :0: ls;
            } else { disengage; }
        } else {
            let rs: list[PidNode] = [here ->:right:->][?:PidNode];
            if len(rs) > 0 {
                self.parent = here;
                self.victim_is_left = False;
                visit :0: rs;
            } else { disengage; }
        }
    }
    can begin with PidRegistry entry {
        print("remove-find registry");
        let roots: list[PidNode] = [here ->][?:PidNode];
        if len(roots) > 0 { visit :0: roots; } else { disengage; }
    }
}

def insert_pid(reg: PidRegistry, pid: int, image: str) -> None {
    let w = reg spawn InsertFind(target_pid=pid);
    if w.hit_existing {
        if w.existing is not None { w.existing.image = image; }
        return;
    }
    let nd = PidNode(pid=pid, image=image, cid="p" + str(pid));
    if w.needs_root { reg ++> nd; }
    elif w.attach_left { w.parent +>: left:+> nd; }
    else { w.parent +>: right:+> nd; }
}

def lookup_image(reg: PidRegistry, pid: int) -> str | None {
    let w = reg spawn Lookup(target_pid=pid);
    if w.found { return w.found_image; }
    return None;
}

def remove_pid(reg: PidRegistry, pid: int) -> bool {
    let w = reg spawn RemoveFind(target_pid=pid);
    if w.victim is None { return False; }
    let ls: list[PidNode] = [w.victim ->:left:->][?:PidNode];
    let rs: list[PidNode] = [w.victim ->:right:->][?:PidNode];
    if len(ls) > 0 or len(rs) > 0 { return False; }
    if w.parent is None { reg <+< w.victim; }
    elif w.victim_is_left { w.parent <+:left:+< w.victim; }
    else { w.parent <+:right:+< w.victim; }
    del w.victim;
    return True;
}

def validate_registry(reg: PidRegistry) -> bool {
    let w = reg spawn Validate;
    return w.ok;
}

def list_pids(reg: PidRegistry) -> list[int] {
    let w = reg spawn CollectAll;
    let out: list[int] = [];
    for p in w.pids { out.append(p); }
    return sorted(out);
}

def boot_self_test(reg: PidRegistry) -> bool {
    print("boot_self_test");
    return validate_registry(reg);
}
