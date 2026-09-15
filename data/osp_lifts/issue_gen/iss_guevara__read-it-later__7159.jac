"""guevara/read-it-later#7159 — adjacency-list hierarchical tree queries."""

node Item {
    has nid: str;
    has ntype: str;
    has parent_id: str = "";
    has depth: int = 0;
}

edge ParentChild {}

walker DescWalk {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];
    has types: list[str] = [];
    can step with Item entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.ids.append(here.nid);
        self.types.append(here.ntype);
        print(here.nid + ":" + here.ntype);
        kids: list[Item] = [here ->:ParentChild:->][?:Item];
        for i in range(len(kids) - 1, -1, -1) {
            visit :0: kids[i];
        }
    }
}

def make_store -> dict[str, Item] {
    store: dict[str, Item] = {};
    return store;
}

def add_node(
    store: dict[str, Item],
    nid: str,
    ntype: str,
    parent_id: str | None = None,
    depth: int = 0
) -> Item {
    nd = Item(nid=nid, ntype=ntype, depth=depth);
    if parent_id is not None {
        nd.parent_id = parent_id;
    }
    store[nid] = nd;
    root ++> nd;
    if parent_id is not None {
        par = store[parent_id] as Item;
        par +>:ParentChild:+> nd;
    }
    return nd;
}

def children_ids(store: dict[str, Item], parent_id: str) -> list[str] {
    out: list[str] = [];
    if parent_id not in store {
        return out;
    }
    par = store[parent_id] as Item;
    kids: list[Item] = [par ->:ParentChild:->][?:Item];
    for ch in kids {
        out.append(ch.nid);
    }
    out.sort();
    return out;
}

def ancestor_ids(store: dict[str, Item], node_id: str) -> list[str] {
    out: list[str] = [];
    if node_id not in store {
        return out;
    }
    chain: list[str] = [];
    cur = store[node_id] as Item;
    pid = cur.parent_id;
    while pid != "" {
        if pid not in store {
            break;
        }
        chain.append(pid);
        par = store[pid] as Item;
        pid = par.parent_id;
    }
    for i in range(len(chain) - 1, -1, -1) {
        out.append(chain[i]);
    }
    return out;
}

def descendant_ids(store: dict[str, Item], root_id: str) -> list[str] {
    out: list[str] = [];
    if root_id not in store {
        return out;
    }
    start = store[root_id] as Item;
    w = DescWalk() spawn start;
    for x in w.ids {
        out.append(x);
    }
    return out;
}

def descendant_types(store: dict[str, Item], root_id: str) -> list[str] {
    out: list[str] = [];
    if root_id not in store {
        return out;
    }
    start = store[root_id] as Item;
    w = DescWalk() spawn start;
    for t in w.types {
        out.append(t);
    }
    return out;
}

with entry {
    store: dict[str, Item] = make_store();
    add_node(store, "1", "course", None, 1);
    add_node(store, "5", "section", "1", 1);
    add_node(store, "7", "courseware", "5", 2);
    add_node(store, "8", "courseware", "5", 2);
    root spawn DescWalk();
}
