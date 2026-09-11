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

test "diamond revisit still cascades once" {
    s: PageStore = make_store();
    a = add_page(s, "a", "A");
    b = add_page(s, "b", "B");
    c = add_page(s, "c", "C");
    d = add_page(s, "d", "D");
    # adversarial insertion order: a->c first, then a->b, b->d, c->d so d is revisited
    link_parent(s, "c", "a");
    link_parent(s, "b", "a");
    link_parent(s, "d", "b");
    link_parent(s, "d", "c");
    cnt = trash_subtree(s, "a");
    assert(cnt == 4);
    assert(is_trashed(s, "a") == True);
    assert(is_trashed(s, "b") == True);
    assert(is_trashed(s, "c") == True);
    assert(is_trashed(s, "d") == True);
}

test "unknown id tolerance" {
    s: PageStore = make_store();
    add_page(s, "x", "X");
    assert(trash_subtree(s, "missing") == 0);
    assert(trash_single_unsafe(s, "missing") == False);
    assert(is_trashed(s, "missing") == False);
    assert(link_parent(s, "missing", "x") == False);
    assert(link_parent(s, "x", "missing") == False);
    assert(get_trashed(s) == []);
}

test "single unsafe does not cascade" {
    s: PageStore = make_store();
    a = add_page(s, "a", "A");
    b = add_page(s, "b", "B");
    cc = add_page(s, "c", "C");
    link_parent(s, "b", "a");
    link_parent(s, "c", "b");
    ok = trash_single_unsafe(s, "a");
    assert(ok == True);
    assert(is_trashed(s, "a") == True);
    assert(is_trashed(s, "b") == False);
    assert(is_trashed(s, "c") == False);
    assert(sorted(get_trashed(s)) == ["a"]);
}

test "repair orphaned descendants" {
    s: PageStore = make_store();
    a = add_page(s, "a", "A");
    b = add_page(s, "b", "B");
    cc = add_page(s, "c", "C");
    link_parent(s, "b", "a");
    link_parent(s, "c", "b");
    trash_single_unsafe(s, "a");
    # simulate drift: children remain live
    assert(is_trashed(s, "b") == False);
    fixed = repair_orphaned(s);
    assert(fixed == 2);
    assert(is_trashed(s, "b") == True);
    assert(is_trashed(s, "c") == True);
    assert(fixed == 2);
}

test "cycle does not loop and still trashes" {
    s: PageStore = make_store();
    a = add_page(s, "a", "A");
    b = add_page(s, "b", "B");
    link_parent(s, "b", "a");
    link_parent(s, "a", "b");
    cnt = trash_subtree(s, "a");
    assert(cnt == 2);
    assert(is_trashed(s, "a") == True);
    assert(is_trashed(s, "b") == True);
}

test "idempotent trash subtree" {
    s: PageStore = make_store();
    a = add_page(s, "a", "A");
    b = add_page(s, "b", "B");
    link_parent(s, "b", "a");
    c1 = trash_subtree(s, "a");
    c2 = trash_subtree(s, "a");
    assert(c1 == 2);
    assert(c2 == 2);
    assert(sorted(get_trashed(s)) == ["a", "b"]);
}
