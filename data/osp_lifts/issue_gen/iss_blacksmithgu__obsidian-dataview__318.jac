"""blacksmithgu/obsidian-dataview#318 — recursive ancestor queries (WITH RECURSIVE lift)."""

node HierarchyRoot {
    has by_id: dict[str, Item] = {};
}

node Item {
    has cid: str;
    has label: str = "";
}

edge Parent {}

def create_hierarchy -> HierarchyRoot {
    hr = HierarchyRoot(by_id={});
    root ++> hr;
    return hr;
}

def register_node(store: HierarchyRoot, node_id: str, label: str = "") -> None {
    if node_id in store.by_id { return; }
    it = Item(cid=node_id, label=label);
    store.by_id[node_id] = it;
    store ++> it;
}

def set_parent(store: HierarchyRoot, child_id: str, parent_id: str) -> None {
    if not (child_id in store.by_id) { return; }
    if not (parent_id in store.by_id) { return; }
    ch = store.by_id[child_id] as Item;
    pa = store.by_id[parent_id] as Item;
    ch +>:Parent:+> pa;
}

def get_parent(store: HierarchyRoot, node_id: str) -> str | None {
    if not (node_id in store.by_id) { return None; }
    it = store.by_id[node_id] as Item;
    pars: list[Item] = [it ->:Parent:->][?:Item];
    if len(pars) == 0 { return None; }
    return pars[0].cid;
}

walker CollectAncestors {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can up with Item entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        parents: list[Item] = [here ->:Parent:->][?:Item];
        for pa in parents {
            self.found.append(pa.cid);
            visit :0: [pa];
        }
        if len(parents) == 0 { disengage; }
        print("ancestors", self.found);
    }
}

def get_ancestors(store: HierarchyRoot, node_id: str) -> list[str] {
    if not (node_id in store.by_id) { return []; }
    start = store.by_id[node_id] as Item;
    w = start spawn CollectAncestors(claimed={}, found=[]);
    out: list[str] = w.found;
    out.sort();
    return out;
}

def get_breadcrumb(store: HierarchyRoot, node_id: str) -> list[str] {
    if not (node_id in store.by_id) { return []; }
    trail: list[str] = [];
    seen: dict[str, bool] = {};
    cur = store.by_id[node_id] as Item;
    done: bool = False;
    while not done {
        trail.append(cur.cid);
        if cur.cid in seen {
            done = True;
        } else {
            seen[cur.cid] = True;
            pars: list[Item] = [cur ->:Parent:->][?:Item];
            if len(pars) == 0 {
                done = True;
            } else {
                cur = pars[0];
            }
        }
    }
    trail.reverse();
    return trail;
}

walker DemoAncestors {
    can run entry {
        st = create_hierarchy();
        register_node(st, "epic", "Epic");
        register_node(st, "project", "Project");
        register_node(st, "story", "Story");
        register_node(st, "task", "Task");
        set_parent(st, "project", "epic");
        set_parent(st, "story", "project");
        set_parent(st, "task", "story");
        tk = st.by_id["task"] as Item;
        w = tk spawn CollectAncestors(claimed={}, found=[]);
        bc = get_breadcrumb(st, "task");
        print("demo breadcrumb", bc);
        print("demo ancestors", w.found);
    }
}

with entry {
    root spawn DemoAncestors;
}
