# iss_diesel-rs__diesel__356.jac
# WITH RECURSIVE row closure — diesel-rs/diesel#356

node Row {
    has rid: str;
}

node GraphStore {
    has rows: dict[str, Row] = {};
}

edge Parent {}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Row entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        self.order.append(here.rid);
        print(["collect", here.rid]);
        kids: list[Row] = [];
        for ch in [here ->:Parent:->][?:Row] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker DepthWalker {
    has claimed: dict[str, bool] = {};
    has depths: dict[str, int] = {};
    has current_depth: int = 0;

    can step with Row entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        self.depths[here.rid] = self.current_depth;
        print(["depth", here.rid, self.current_depth]);
        kids: list[Row] = [];
        for ch in [here ->:Parent:->][?:Row] {
            kids.append(ch);
        }
        if kids {
            for kid in kids {
                self.current_depth = self.current_depth + 1;
                visit [kid];
                self.current_depth = self.current_depth - 1;
            }
        } else {
            disengage;
        }
    }
}

def create_store -> GraphStore {
    gs = GraphStore();
    root ++> gs;
    return gs;
}

def add_row(store: GraphStore, rid: str) -> Row {
    r = Row(rid=rid);
    store.rows[rid] = r;
    root ++> r;
    return r;
}

def link_parent(store: GraphStore, parent_rid: str, child_rid: str) -> bool {
    if parent_rid not in store.rows {
        return False;
    }
    if child_rid not in store.rows {
        return False;
    }
    p = store.rows[parent_rid];
    c = store.rows[child_rid];
    p +>:Parent:+> c;
    return True;
}

def with_recursive_collect(store: GraphStore, root_rid: str) -> list[str] {
    if root_rid not in store.rows {
        empty: list[str] = [];
        return empty;
    }
    start = store.rows[root_rid];
    w = start spawn CollectWalker(claimed={}, order=[]);
    return w.order;
}

def with_recursive_depths(store: GraphStore, root_rid: str) -> dict[str, int] {
    if root_rid not in store.rows {
        empty: dict[str, int] = {};
        return empty;
    }
    start = store.rows[root_rid];
    w = start spawn DepthWalker(claimed={}, depths={}, current_depth=0);
    return w.depths;
}

test "collect_singleton" {
    store = create_store();
    add_row(store, "a");
    got = with_recursive_collect(store, "a");
    assert got == ["a"];
}

test "collect_tree_dfs" {
    store = create_store();
    add_row(store, "a");
    add_row(store, "b");
    add_row(store, "c");
    link_parent(store, "a", "b");
    link_parent(store, "a", "c");
    got = with_recursive_collect(store, "a");
    assert got == ["a", "b", "c"];
}

test "unknown_root_collect_empty" {
    store = create_store();
    got = with_recursive_collect(store, "missing");
    assert got == [];
}

test "link_parent_missing_ids" {
    store = create_store();
    add_row(store, "a");
    assert link_parent(store, "a", "x") == False;
    assert link_parent(store, "x", "a") == False;
}

test "depths_linear" {
    store = create_store();
    add_row(store, "a");
    add_row(store, "b");
    link_parent(store, "a", "b");
    got = with_recursive_depths(store, "a");
    assert got == {"a": 0, "b": 1};
}

test "diamond_revisit_once" {
    store = create_store();
    add_row(store, "a");
    add_row(store, "b");
    add_row(store, "c");
    link_parent(store, "a", "b");
    link_parent(store, "a", "c");
    link_parent(store, "b", "c");
    got = with_recursive_collect(store, "a");
    assert len(got) == 3;
    assert sorted(got) == ["a", "b", "c"];
}
