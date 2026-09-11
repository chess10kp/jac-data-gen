"""rhythmatician/voxygen-monorepo#39 — truth trace registry for guidance lineage."""

node Item {
    has cid: str;
    has title: str;
    has truth_level: int = 0;
    has status: str = "active";
}

edge ParentChild {}
edge Depends {}
edge References {}

walker BootWalker {
    can boot with Item entry {
        print("issue39 truth trace ready ", here.cid);
        disengage;
    }
}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can descend with Item entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        kids: list[Item] = [];
        for ch in [here ->:ParentChild:->][?:Item] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker AncestorWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can ascend with Item entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        parents: list[Item] = [];
        for p in [<-:ParentChild:<-][?:Item] {
            parents.append(p);
        }
        if len(parents) > 0 {
            visit :0: parents;
        } else {
            disengage;
        }
    }
}

def seed_anchor() -> Item {
    anchor = Item(cid="__root__", title="voxygen-monorepo", truth_level=1);
    root ++> anchor;
    return anchor;
}

def put_item(store: dict[str, Item], anchor: Item, cid: str, title: str, level: int) {
    nd = Item(cid=cid, title=title, truth_level=level);
    anchor ++> nd;
    store[cid] = nd;
}

def link_child(store: dict[str, Item], parent_id: str, child_id: str) {
    if parent_id not in store {
        return;
    }
    if child_id not in store {
        return;
    }
    parent = store[parent_id] as Item;
    child = store[child_id] as Item;
    parent +>:ParentChild:+> child;
}

def link_depends(store: dict[str, Item], blocker_id: str, blocked_id: str) {
    if blocker_id not in store {
        return;
    }
    if blocked_id not in store {
        return;
    }
    blocker = store[blocker_id] as Item;
    blocked = store[blocked_id] as Item;
    blocker +>:Depends:+> blocked;
}

def link_reference(store: dict[str, Item], source_id: str, target_id: str) {
    if source_id not in store {
        return;
    }
    if target_id not in store {
        return;
    }
    src = store[source_id] as Item;
    tgt = store[target_id] as Item;
    src +>:References:+> tgt;
}

def closure_ids(store: dict[str, Item], root_id: str) -> list[str] {
    if root_id not in store {
        empty: list[str] = [];
        return empty;
    }
    start = store[root_id] as Item;
    w = start spawn ClosureWalker(claimed={});
    out: list[str] = [];
    for cid in w.found {
        out.append(cid);
    }
    out.sort();
    return out;
}

def ancestor_ids(store: dict[str, Item], item_id: str) -> list[str] {
    if item_id not in store {
        empty: list[str] = [];
        return empty;
    }
    start = store[item_id] as Item;
    w = start spawn AncestorWalker(claimed={});
    out: list[str] = [];
    for cid in w.found {
        out.append(cid);
    }
    out.sort();
    return out;
}

def blocker_ids(store: dict[str, Item], item_id: str) -> list[str] {
    if item_id not in store {
        empty: list[str] = [];
        return empty;
    }
    target = store[item_id] as Item;
    out: list[str] = [];
    for src in [<-:Depends:<-][?:Item] {
        out.append(src.cid);
    }
    out.sort();
    return out;
}

def item_truth_level(store: dict[str, Item], item_id: str) -> int {
    if item_id not in store {
        return 0;
    }
    nd = store[item_id] as Item;
    return nd.truth_level;
}

with entry {
    anchor = seed_anchor();
    root spawn BootWalker();
}
