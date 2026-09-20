"""mikeev261/HidHide#12 — PID-to-image registry OSP lift."""

node ProcessEntry {
    has pid: int;
    has image: str;
}

edge LessPid {}
edge GreaterPid {}
edge Invalidates {}

node WhitelistSlot {
    has key: str;
    has valid: bool = True;
}

node PidRegistry {
    has boot_self_test_ran: bool = False;
}

walker FindWalker {
    has target: int;
    has found_image: str = "";
    has match: ProcessEntry = None;
    has hit: bool = False;

    can seek with ProcessEntry entry {
        print("find", here.pid);
        if here.pid == self.target {
            self.found_image = here.image;
            self.match = here;
            self.hit = True;
            disengage;
        }
        if self.target < here.pid {
            for ch in [here ->:LessPid:->][?:ProcessEntry] {
                visit [ch];
            } else {
                disengage;
            }
        } else {
            for ch in [here ->:GreaterPid:->][?:ProcessEntry] {
                visit [ch];
            } else {
                disengage;
            }
        }
    }
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has pids: list[int] = [];

    can step with ProcessEntry entry {
        print("collect", here.pid);
        pid_key: str = str(here.pid);
        if pid_key in self.claimed {
            skip;
        }
        self.claimed[pid_key] = True;
        self.pids.append(here.pid);
        kids: list[ProcessEntry] = [];
        for ch in [here ->:LessPid:->][?:ProcessEntry] {
            kids.append(ch);
        }
        for ch in [here ->:GreaterPid:->][?:ProcessEntry] {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

walker InvalidateWalker {
    has claimed: dict[str, bool] = {};
    has touched: list[str] = [];

    can sweep with ProcessEntry entry {
        print("invalidate", here.pid);
        pid_key: str = str(here.pid);
        if pid_key in self.claimed {
            skip;
        }
        self.claimed[pid_key] = True;
        slots: list[WhitelistSlot] = [];
        for sl in [here ->:Invalidates:->][?:WhitelistSlot] {
            slots.append(sl);
        }
        for sl in slots {
            sl.valid = False;
            self.touched.append(sl.key);
        }
        kids: list[ProcessEntry] = [];
        for ch in [here ->:LessPid:->][?:ProcessEntry] {
            kids.append(ch);
        }
        for ch in [here ->:GreaterPid:->][?:ProcessEntry] {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

def find_entry_root(reg: PidRegistry) -> ProcessEntry | None {
    for nd in [reg ->>][?:ProcessEntry] {
        return nd;
    }
    return None;
}

def insert_into(parent: ProcessEntry, pid: int, image: str) {
    if pid < parent.pid {
        kids: list[ProcessEntry] = [];
        for ch in [parent ->:LessPid:->][?:ProcessEntry] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            child = ProcessEntry(pid=pid, image=image);
            parent +>:LessPid:+> child;
        } else {
            insert_into(kids[0], pid, image);
        }
    } else {
        if pid > parent.pid {
            kids: list[ProcessEntry] = [];
            for ch in [parent ->:GreaterPid:->][?:ProcessEntry] {
                kids.append(ch);
            }
            if len(kids) == 0 {
                child = ProcessEntry(pid=pid, image=image);
                parent +>:GreaterPid:+> child;
            } else {
                insert_into(kids[0], pid, image);
            }
        } else {
            parent.image = image;
        }
    }
}

def create_registry -> PidRegistry {
    reg = PidRegistry();
    root ++> reg;
    return reg;
}

def insert_mapping(reg: PidRegistry, pid: int, image: str) -> None {
    graph_root = find_entry_root(reg);
    if graph_root is None {
        entry = ProcessEntry(pid=pid, image=image);
        reg ++> entry;
        return;
    }
    insert_into(graph_root, pid, image);
}

def find_node(reg: PidRegistry, pid: int) -> ProcessEntry | None {
    graph_root = find_entry_root(reg);
    if graph_root is None {
        return None;
    }
    w = graph_root spawn FindWalker(target=pid);
    if w.hit {
        return w.match;
    }
    return None;
}

def lookup_image(reg: PidRegistry, pid: int) -> str | None {
    graph_root = find_entry_root(reg);
    if graph_root is None {
        return None;
    }
    w = graph_root spawn FindWalker(target=pid);
    if w.hit {
        return w.found_image;
    }
    return None;
}

def list_mapped_pids(reg: PidRegistry) -> list[int] {
    graph_root = find_entry_root(reg);
    if graph_root is None {
        return [];
    }
    w = graph_root spawn CollectWalker();
    return sorted(w.pids);
}

def attach_cache(entry: ProcessEntry, slot: WhitelistSlot) {
    entry +>:Invalidates:+> slot;
}

def invalidate_caches_for_subtree(reg: PidRegistry) -> list[str] {
    graph_root = find_entry_root(reg);
    if graph_root is None {
        return [];
    }
    w = graph_root spawn InvalidateWalker();
    return sorted(w.touched);
}

def run_consistency_check(reg: PidRegistry) -> bool {
    pids = list_mapped_pids(reg);
    for p in pids {
        img = lookup_image(reg, p);
        if img is None {
            return False;
        }
        if len(img) == 0 {
            return False;
        }
    }
    return True;
}

def remove_mapping(reg: PidRegistry, pid: int) -> bool {
    target = find_node(reg, pid);
    if target is None {
        return False;
    }
    left_kids: list[ProcessEntry] = [];
    for ch in [target ->:LessPid:->][?:ProcessEntry] {
        left_kids.append(ch);
    }
    right_kids: list[ProcessEntry] = [];
    for ch in [target ->:GreaterPid:->][?:ProcessEntry] {
        right_kids.append(ch);
    }
    if len(left_kids) > 0 or len(right_kids) > 0 {
        return False;
    }
    destroy target;
    return True;
}

"""mikeev261/HidHide#12 — PID-to-image registry OSP lift."""

node ProcessEntry {
    has pid: int;
    has image: str;
}

edge LessPid {}
edge GreaterPid {}
edge Invalidates {}

node WhitelistSlot {
    has key: str;
    has valid: bool = True;
}

node PidRegistry {
    has boot_self_test_ran: bool = False;
}

walker FindWalker {
    has target: int;
    has found_image: str = "";
    has match: ProcessEntry = None;
    has hit: bool = False;

    can seek with ProcessEntry entry {
        print("find", here.pid);
        if here.pid == self.target {
            self.found_image = here.image;
            self.match = here;
            self.hit = True;
            disengage;
        }
        if self.target < here.pid {
            for ch in [here ->:LessPid:->][?:ProcessEntry] {
                visit [ch];
            } else {
                disengage;
            }
        } else {
            for ch in [here ->:GreaterPid:->][?:ProcessEntry] {
                visit [ch];
            } else {
                disengage;
            }
        }
    }
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has pids: list[int] = [];

    can step with ProcessEntry entry {
        print("collect", here.pid);
        pid_key: str = str(here.pid);
        if pid_key in self.claimed {
            skip;
        }
        self.claimed[pid_key] = True;
        self.pids.append(here.pid);
        kids: list[ProcessEntry] = [];
        for ch in [here ->:LessPid:->][?:ProcessEntry] {
            kids.append(ch);
        }
        for ch in [here ->:GreaterPid:->][?:ProcessEntry] {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

walker InvalidateWalker {
    has claimed: dict[str, bool] = {};
    has touched: list[str] = [];

    can sweep with ProcessEntry entry {
        print("invalidate", here.pid);
        pid_key: str = str(here.pid);
        if pid_key in self.claimed {
            skip;
        }
        self.claimed[pid_key] = True;
        slots: list[WhitelistSlot] = [];
        for sl in [here ->:Invalidates:->][?:WhitelistSlot] {
            slots.append(sl);
        }
        for sl in slots {
            sl.valid = False;
            self.touched.append(sl.key);
        }
        kids: list[ProcessEntry] = [];
        for ch in [here ->:LessPid:->][?:ProcessEntry] {
            kids.append(ch);
        }
        for ch in [here ->:GreaterPid:->][?:ProcessEntry] {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

def find_entry_root(reg: PidRegistry) -> ProcessEntry | None {
    for nd in [reg ->>][?:ProcessEntry] {
        return nd;
    }
    return None;
}

def insert_into(parent: ProcessEntry, pid: int, image: str) {
    if pid < parent.pid {
        kids: list[ProcessEntry] = [];
        for ch in [parent ->:LessPid:->][?:ProcessEntry] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            child = ProcessEntry(pid=pid, image=image);
            parent +>:LessPid:+> child;
        } else {
            insert_into(kids[0], pid, image);
        }
    } else {
        if pid > parent.pid {
            kids: list[ProcessEntry] = [];
            for ch in [parent ->:GreaterPid:->][?:ProcessEntry] {
                kids.append(ch);
            }
            if len(kids) == 0 {
                child = ProcessEntry(pid=pid, image=image);
                parent +>:GreaterPid:+> child;
            } else {
                insert_into(kids[0], pid, image);
            }
        } else {
            parent.image = image;
        }
    }
}

def create_registry -> PidRegistry {
    reg = PidRegistry();
    root ++> reg;
    return reg;
}

def insert_mapping(reg: PidRegistry, pid: int, image: str) -> None {
    graph_root = find_entry_root(reg);
    if graph_root is None {
        entry = ProcessEntry(pid=pid, image=image);
        reg ++> entry;
        return;
    }
    insert_into(graph_root, pid, image);
}

def find_node(reg: PidRegistry, pid: int) -> ProcessEntry | None {
    graph_root = find_entry_root(reg);
    if graph_root is None {
        return None;
    }
    w = graph_root spawn FindWalker(target=pid);
    if w.hit {
        return w.match;
    }
    return None;
}

def lookup_image(reg: PidRegistry, pid: int) -> str | None {
    graph_root = find_entry_root(reg);
    if graph_root is None {
        return None;
    }
    w = graph_root spawn FindWalker(target=pid);
    if w.hit {
        return w.found_image;
    }
    return None;
}

def list_mapped_pids(reg: PidRegistry) -> list[int] {
    graph_root = find_entry_root(reg);
    if graph_root is None {
        return [];
    }
    w = graph_root spawn CollectWalker();
    return sorted(w.pids);
}

def attach_cache(entry: ProcessEntry, slot: WhitelistSlot) {
    entry +>:Invalidates:+> slot;
}

def invalidate_caches_for_subtree(reg: PidRegistry) -> list[str] {
    graph_root = find_entry_root(reg);
    if graph_root is None {
        return [];
    }
    w = graph_root spawn InvalidateWalker();
    return sorted(w.touched);
}

def run_consistency_check(reg: PidRegistry) -> bool {
    pids = list_mapped_pids(reg);
    for p in pids {
        img = lookup_image(reg, p);
        if img is None {
            return False;
        }
        if len(img) == 0 {
            return False;
        }
    }
    return True;
}

def remove_mapping(reg: PidRegistry, pid: int) -> bool {
    target = find_node(reg, pid);
    if target is None {
        return False;
    }
    left_kids: list[ProcessEntry] = [];
    for ch in [target ->:LessPid:->][?:ProcessEntry] {
        left_kids.append(ch);
    }
    right_kids: list[ProcessEntry] = [];
    for ch in [target ->:GreaterPid:->][?:ProcessEntry] {
        right_kids.append(ch);
    }
    if len(left_kids) > 0 or len(right_kids) > 0 {
        return False;
    }
    destroy target;
    return True;
}

test "insert_and_lookup" {
    reg = create_registry();
    insert_mapping(reg, 100, "boot.exe");
    insert_mapping(reg, 50, "left.exe");
    insert_mapping(reg, 150, "right.exe");
    assert lookup_image(reg, 50) == "left.exe";
    assert lookup_image(reg, 100) == "boot.exe";
    assert lookup_image(reg, 150) == "right.exe";
    assert lookup_image(reg, 999) is None;
}

test "list_mapped_sorted" {
    reg = create_registry();
    insert_mapping(reg, 300, "c.exe");
    insert_mapping(reg, 100, "a.exe");
    insert_mapping(reg, 200, "b.exe");
    assert list_mapped_pids(reg) == [100, 200, 300];
}

test "consistency_check_passes" {
    reg = create_registry();
    insert_mapping(reg, 42, "svc.exe");
    insert_mapping(reg, 10, "child.exe");
    assert run_consistency_check(reg) is True;
}

test "remove_leaf_only" {
    reg = create_registry();
    insert_mapping(reg, 100, "root.exe");
    insert_mapping(reg, 50, "leaf.exe");
    assert remove_mapping(reg, 50) is True;
    assert lookup_image(reg, 50) is None;
    assert lookup_image(reg, 100) == "root.exe";
    assert remove_mapping(reg, 100) is False;
}

test "invalidate_caches" {
    reg = create_registry();
    insert_mapping(reg, 100, "root.exe");
    entry = find_node(reg, 100);
    slot_a = WhitelistSlot(key="cache-a");
    slot_b = WhitelistSlot(key="cache-b");
    root ++> slot_a;
    root ++> slot_b;
    attach_cache(entry, slot_a);
    attach_cache(entry, slot_b);
    touched = invalidate_caches_for_subtree(reg);
    assert touched == ["cache-a", "cache-b"];
    assert slot_a.valid is False;
    assert slot_b.valid is False;
}

test "update_existing_pid" {
    reg = create_registry();
    insert_mapping(reg, 77, "old.exe");
    insert_mapping(reg, 77, "new.exe");
    assert lookup_image(reg, 77) == "new.exe";
    assert list_mapped_pids(reg) == [77];
}
