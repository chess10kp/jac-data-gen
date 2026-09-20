"""payloadcms/payload#17457 — nested docs resaveChildren cascade with silent rollback."""

node Catalog {
    has logs: list[str] = [];
}

node Page {
    has cid: str;
    has updated_at: int = 0;
    has label: str = "";
    has valid: bool = True;
}

edge ChildOf {}

walker ResaveWalker {
    has claimed: dict[str, bool] = {};
    has failed: bool = False;
    has resave_root: str = "";

    can step with Page entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid != self.resave_root {
            print("resave " + here.cid);
            here.updated_at = here.updated_at + 1;
            if here.valid == False {
                self.failed = True;
            }
        }
        kids: list[Page] = [here ->:ChildOf:->][?:Page];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

def find_page(cid: str) -> Page | None {
    candidates: list[Page] = [root -->][?:Page];
    for pg in candidates {
        if pg.cid == cid {
            return pg;
        }
    }
    return None;
}

def make_store() -> Catalog {
    cat = Catalog();
    root ++> cat;
    return cat;
}

def add_page(store: Catalog, cid: str, parent_cid: str | None, valid: bool) -> bool {
    if find_page(cid) != None {
        return False;
    }
    pg = Page(cid=cid, valid=valid);
    root ++> pg;
    if parent_cid != None {
        par = find_page(parent_cid);
        if par == None {
            return False;
        }
        par +>:ChildOf:+> pg;
    }
    return True;
}

def link_child(store: Catalog, parent_cid: str, child_cid: str) -> bool {
    par = find_page(parent_cid);
    ch = find_page(child_cid);
    if par == None or ch == None {
        return False;
    }
    par +>:ChildOf:+> ch;
    return True;
}

def set_page_valid(store: Catalog, cid: str, valid: bool) -> bool {
    pg = find_page(cid);
    if pg == None {
        return False;
    }
    pg.valid = valid;
    return True;
}

def persisted_updated_at(store: Catalog, cid: str) -> int {
    pg = find_page(cid);
    if pg == None {
        return -1;
    }
    return pg.updated_at;
}

def response_logs(store: Catalog) -> list[str] {
    return store.logs;
}

def update_parent(store: Catalog, parent_cid: str, label: str) -> dict {
    result: dict = {};
    par = find_page(parent_cid);
    if par == None {
        result["ok"] = False;
        result["updated_at"] = 0;
        return result;
    }
    snap_at: dict[str, int] = {};
    snap_label: dict[str, str] = {};
    pages: list[Page] = [root -->][?:Page];
    for pg in pages {
        snap_at[pg.cid] = pg.updated_at;
        snap_label[pg.cid] = pg.label;
    }
    par.label = label;
    par.updated_at = par.updated_at + 1;
    w = par spawn ResaveWalker(claimed={}, resave_root=parent_cid);
    new_ts = par.updated_at;
    if w.failed {
        msg = "Nested Docs plugin encountered an error while re-saving a child document.";
        store.logs.append(msg);
        for pg in pages {
            pg.updated_at = snap_at[pg.cid];
            pg.label = snap_label[pg.cid];
        }
    }
    result["ok"] = True;
    result["updated_at"] = new_ts;
    return result;
}

with entry {
    demo_store = make_store();
    add_page(demo_store, "A", None, True);
    add_page(demo_store, "B", "A", True);
    root spawn ResaveWalker(claimed={}, resave_root="");
}
