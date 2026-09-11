node Page {
    has pid: str;
    has title: str;
    has isTrashed: bool = false;
}

edge ParentChild {}

obj PageStore {
    has pages: dict[str, Page] = {};
}

walker TrashCascade {
    has claimed: dict[str, bool] = {};
    has count: int = 0;
    can cascade with Page entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        if not here.isTrashed {
            here.isTrashed = True;
        }
        self.count += 1;
        print(here.pid);
        for kid in [here ->:ParentChild:->][?:Page] {
            visit [:0:][kid];
        }
    } else { disengage; }
}

walker CollectTrashed {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];
    can collect with Page entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        if here.isTrashed {
            self.result.append(here.pid);
        }
        for kid in [here ->:ParentChild:->][?:Page] {
            visit [:0:][kid];
        }
        print(here.pid);
    } else { disengage; }
}

walker OrphanProbe {
    has claimed: dict[str, bool] = {};
    has orphans: list[Page] = [];
    can probe with Page entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        if not here.isTrashed {
            self.orphans.append(here);
        }
        for kid in [here ->:ParentChild:->][?:Page] {
            visit [:0:][kid];
        }
        print(here.pid);
    } else { disengage; }
}

def make_store -> PageStore {
    s: PageStore = PageStore();
    return s;
}

def add_page(store: PageStore, pid: str, title: str) -> Page {
    # single owner for node creation
    p: Page = Page(pid=pid, title=title);
    store.pages[pid] = p;
    return p;
}

def link_parent(store: PageStore, child_id: str, parent_id: str) -> bool {
    if child_id not in store.pages { return False; }
    if parent_id not in store.pages { return False; }
    ch: Page = store.pages[child_id];
    pa: Page = store.pages[parent_id];
    pa +>:ParentChild:+> ch;
    return True;
}

def trash_subtree(store: PageStore, root_id: str) -> int {
    if root_id not in store.pages { return 0; }
    start: Page = store.pages[root_id];
    w = start spawn TrashCascade();
    return w.count;
}

def trash_single_unsafe(store: PageStore, pid: str) -> bool {
    if pid not in store.pages { return False; }
    p: Page = store.pages[pid];
    p.isTrashed = True;
    return True;
}

def get_trashed(store: PageStore) -> list[str] {
    out: list[str] = [];
    for pid in store.pages {
        p: Page = store.pages[pid];
        if p.isTrashed {
            out.append(pid);
        }
    }
    return out;
}

def is_trashed(store: PageStore, pid: str) -> bool {
    if pid not in store.pages { return False; }
    return store.pages[pid].isTrashed;
}

def repair_orphaned(store: PageStore) -> int {
    done: dict[str, bool] = {};
    total: int = 0;
    for pid in store.pages {
        p: Page = store.pages[pid];
        if p.isTrashed {
            w = p spawn OrphanProbe();
            for o in w.orphans {
                if o.pid not in done {
                    done[o.pid] = True;
                    if not o.isTrashed {
                        o.isTrashed = True;
                        total += 1;
                    }
                }
            }
        }
    }
    return total;
}

with entry {
    s: PageStore = make_store();
    r = add_page(s, "r", "root");
    c = add_page(s, "c", "child");
    link_parent(s, "c", "r");
    trash_subtree(s, "r");
    print("demo done");
}
