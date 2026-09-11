node Page {
    has page_id: str;
    has is_trashed: bool = False;
    has trashed_at: str = "";
}

edge Child {}

node Store {
    has store_id: str = "store";
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has found: list[Page] = [];
    can collect with Page entry {
        if here.page_id in self.claimed { skip; }
        self.claimed[here.page_id] = True;
        self.found.append(here);
        kids: list[Page] = [];
        for ch in [here ->:Child:->][?:Page] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit kids;
        } else {
            disengage;
        }
        print(here.page_id);
    }
}

walker EntryWalker {
    has claimed: dict[str, bool] = {};
    can start with Store entry {
        if here.store_id in self.claimed { skip; }
        self.claimed[here.store_id] = True;
        print(here.store_id);
        disengage;
    }
}

def get_page(graph_root: Store, page_id: str) -> Page | None {
    for nd in [graph_root -->][?:Page] {
        if nd.page_id == page_id {
            return nd;
        }
    }
    return None;
}

def create_page(graph_root: Store, page_id: str, parent_id: str | None) -> Page | None {
    # single owner helper for building the tree
    existing: Page | None = get_page(graph_root, page_id);
    if existing is not None {
        return None;
    }
    nd = Page(page_id=page_id);
    graph_root ++> nd;
    if parent_id is not None {
        parent: Page | None = get_page(graph_root, parent_id);
        if parent is not None {
            parent +>:Child:+> nd;
        }
    }
    print(page_id);
    return nd;
}

def trash_single_page_unsafe(graph_root: Store, page_id: str) -> bool {
    nd: Page | None = get_page(graph_root, page_id);
    if nd is None {
        print("not found");
        return False;
    }
    if nd.is_trashed == False {
        nd.is_trashed = True;
        nd.trashed_at = "now";
    }
    print(page_id);
    return True;
}

def recursively_trash(graph_root: Store, page_id: str) -> int {
    nd: Page | None = get_page(graph_root, page_id);
    if nd is None {
        return 0;
    }
    w = nd spawn CollectWalker(claimed={});
    cnt: int = 0;
    for p in w.found {
        if p.is_trashed == False {
            p.is_trashed = True;
            p.trashed_at = "now";
            cnt += 1;
        }
    }
    print("recursively trashed");
    return cnt;
}

def repair_orphaned_trashed_pages(graph_root: Store) -> int {
    # repairs drift created by trash_single_page_unsafe / raw writers
    fixed: int = 0;
    all: list[Page] = [];
    for nd in [graph_root -->][?:Page] {
        all.append(nd);
    }
    for pg in all {
        if pg.is_trashed == True {
            w = pg spawn CollectWalker(claimed={});
            for kid in w.found {
                if kid.is_trashed == False {
                    kid.is_trashed = True;
                    kid.trashed_at = "now";
                    fixed += 1;
                }
            }
        }
    }
    print("repaired");
    return fixed;
}

def list_trashed(graph_root: Store) -> list[str] {
    out: list[str] = [];
    for nd in [graph_root -->][?:Page] {
        if nd.is_trashed == True {
            out.append(nd.page_id);
        }
    }
    out = sorted(out);
    print("listed");
    return out;
}

with entry {
    s = Store(store_id="demo");
    root ++> s;
    w = s spawn EntryWalker();
    print("entry");
}
