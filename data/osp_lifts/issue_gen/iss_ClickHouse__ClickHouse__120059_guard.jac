"""ClickHouse/ClickHouse#120059 — recursive CTE GLOBAL join never converges."""

node TreeVertex {
    has cid: str;
    has parent_id: str;
}

edge Child {}

node TreeStore {
    has by_id: dict[str, TreeVertex] = {};
    has kids: dict[str, list[str]] = {};
}

def build_tree(rows: list[list[str]]) -> TreeStore {
    store = TreeStore();
    for row in rows {
        vid = row[0];
        pid = row[1];
        vtx = TreeVertex(cid=vid, parent_id=pid);
        store.by_id[vid] = vtx;
        if pid not in store.kids {
            store.kids[pid] = [];
        }
        bucket = store.kids[pid];
        bucket.append(vid);
    }
    for vid in store.by_id {
        vtx = store.by_id[vid];
        pid = vtx.parent_id;
        is_root = (pid == "") or (pid not in store.by_id);
        if is_root {
            root ++> vtx;
        }
        if pid in store.by_id {
            par = store.by_id[pid];
            par +>:Child:+> vtx;
        }
    }
    return store;
}

def join_step(store: TreeStore, partner: list[list]) -> list[list] {
    out: list[list] = [];
    for pr in partner {
        st_id = pr[0] as str;
        st_depth = pr[1] as int;
        if st_id in store.kids {
            ch_ids = store.kids[st_id];
            for ch_id in ch_ids {
                nr: list = [];
                nr.append(ch_id);
                nr.append(st_depth + 1);
                out.append(nr);
            }
        }
    }
    return out;
}

def row_key(row: list) -> str {
    return (row[0] as str) + ":" + str(row[1] as int);
}

def dedupe_new_rows(working: list[list], new_rows: list[list]) -> list[list] {
    seen: dict[str, bool] = {};
    for wr in working {
        seen[row_key(wr)] = True;
    }
    out: list[list] = [];
    for nr in new_rows {
        k = row_key(nr);
        if k not in seen {
            out.append(nr);
            seen[k] = True;
        }
    }
    return out;
}

def count_recursive_cte(store: TreeStore, join_mode: str, max_depth: int) -> int {
    working: list[list] = [];
    ids: list[str] = [];
    for vid in store.by_id {
        ids.append(vid);
    }
    ids = sorted(ids);
    for vid in ids {
        seed: list = [];
        seed.append(vid);
        seed.append(0);
        working.append(seed);
    }
    total = len(working);
    frozen: list[list] | None = None;
    iter_n = 0;
    last_new: list[list] = [];
    while iter_n < max_depth {
        new_rows: list[list] = [];
        if join_mode == "global" {
            if frozen is None {
                frozen = join_step(store, working);
                new_rows = frozen;
            } else {
                new_rows = frozen;
            }
        } else {
            new_rows = join_step(store, working);
            new_rows = dedupe_new_rows(working, new_rows);
        }
        if len(new_rows) == 0 {
            break;
        }
        for nr in new_rows {
            working.append(nr);
        }
        total = total + len(new_rows);
        last_new = new_rows;
        iter_n = iter_n + 1;
    }
    if join_mode == "global" and iter_n >= max_depth and len(last_new) > 0 and max_depth > 1 {
        raise RuntimeError("TOO_DEEP_RECURSION");
    }
    return total;
}

walker TreeWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can begin with root entry {
        tops: list[TreeVertex] = [root ->][?:TreeVertex];
        for v in tops {
            visit :0: [v];
        }
    }
    can step with TreeVertex entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        nbrs: list[TreeVertex] = [here ->:Child:->][?:TreeVertex];
        for ch in nbrs {
            visit :0: [ch];
        }
    }
}

def walk_tree_order(store: TreeStore) -> list[str] {
    w = root spawn TreeWalk(claimed={}, order=[]);
    return sorted(w.order);
}

with entry {
    rows: list[list[str]] = [];
    ra: list[str] = [];
    ra.append("a");
    ra.append("");
    rows.append(ra);
    rb: list[str] = [];
    rb.append("b");
    rb.append("a");
    rows.append(rb);
    rc: list[str] = [];
    rc.append("c");
    rc.append("b");
    rows.append(rc);
    store = build_tree(rows);
    n = count_recursive_cte(store, "local", 20);
    print(n);
    tw = root spawn TreeWalk(claimed={}, order=[]);
}

"""ClickHouse/ClickHouse#120059 — recursive CTE GLOBAL join never converges."""

node TreeVertex {
    has cid: str;
    has parent_id: str;
}

edge Child {}

node TreeStore {
    has by_id: dict[str, TreeVertex] = {};
    has kids: dict[str, list[str]] = {};
}

def build_tree(rows: list[list[str]]) -> TreeStore {
    store = TreeStore();
    for row in rows {
        vid = row[0];
        pid = row[1];
        vtx = TreeVertex(cid=vid, parent_id=pid);
        store.by_id[vid] = vtx;
        if pid not in store.kids {
            store.kids[pid] = [];
        }
        bucket = store.kids[pid];
        bucket.append(vid);
    }
    for vid in store.by_id {
        vtx = store.by_id[vid];
        pid = vtx.parent_id;
        is_root = (pid == "") or (pid not in store.by_id);
        if is_root {
            root ++> vtx;
        }
        if pid in store.by_id {
            par = store.by_id[pid];
            par +>:Child:+> vtx;
        }
    }
    return store;
}

def join_step(store: TreeStore, partner: list[list]) -> list[list] {
    out: list[list] = [];
    for pr in partner {
        st_id = pr[0] as str;
        st_depth = pr[1] as int;
        if st_id in store.kids {
            ch_ids = store.kids[st_id];
            for ch_id in ch_ids {
                nr: list = [];
                nr.append(ch_id);
                nr.append(st_depth + 1);
                out.append(nr);
            }
        }
    }
    return out;
}

def row_key(row: list) -> str {
    return (row[0] as str) + ":" + str(row[1] as int);
}

def dedupe_new_rows(working: list[list], new_rows: list[list]) -> list[list] {
    seen: dict[str, bool] = {};
    for wr in working {
        seen[row_key(wr)] = True;
    }
    out: list[list] = [];
    for nr in new_rows {
        k = row_key(nr);
        if k not in seen {
            out.append(nr);
            seen[k] = True;
        }
    }
    return out;
}

def count_recursive_cte(store: TreeStore, join_mode: str, max_depth: int) -> int {
    working: list[list] = [];
    ids: list[str] = [];
    for vid in store.by_id {
        ids.append(vid);
    }
    ids = sorted(ids);
    for vid in ids {
        seed: list = [];
        seed.append(vid);
        seed.append(0);
        working.append(seed);
    }
    total = len(working);
    frozen: list[list] | None = None;
    iter_n = 0;
    last_new: list[list] = [];
    while iter_n < max_depth {
        new_rows: list[list] = [];
        if join_mode == "global" {
            if frozen is None {
                frozen = join_step(store, working);
                new_rows = frozen;
            } else {
                new_rows = frozen;
            }
        } else {
            new_rows = join_step(store, working);
            new_rows = dedupe_new_rows(working, new_rows);
        }
        if len(new_rows) == 0 {
            break;
        }
        for nr in new_rows {
            working.append(nr);
        }
        total = total + len(new_rows);
        last_new = new_rows;
        iter_n = iter_n + 1;
    }
    if join_mode == "global" and iter_n >= max_depth and len(last_new) > 0 and max_depth > 1 {
        raise RuntimeError("TOO_DEEP_RECURSION");
    }
    return total;
}

walker TreeWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can begin with root entry {
        tops: list[TreeVertex] = [root ->][?:TreeVertex];
        for v in tops {
            visit :0: [v];
        }
    }
    can step with TreeVertex entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        nbrs: list[TreeVertex] = [here ->:Child:->][?:TreeVertex];
        for ch in nbrs {
            visit :0: [ch];
        }
    }
}

def walk_tree_order(store: TreeStore) -> list[str] {
    w = root spawn TreeWalk(claimed={}, order=[]);
    return sorted(w.order);
}

with entry {
    rows: list[list[str]] = [];
    ra: list[str] = [];
    ra.append("a");
    ra.append("");
    rows.append(ra);
    rb: list[str] = [];
    rb.append("b");
    rb.append("a");
    rows.append(rb);
    rc: list[str] = [];
    rc.append("c");
    rc.append("b");
    rows.append(rc);
    store = build_tree(rows);
    n = count_recursive_cte(store, "local", 20);
    print(n);
    tw = root spawn TreeWalk(claimed={}, order=[]);
}

test "local_converges_six" {
    rows: list[list[str]] = [];
    ra: list[str] = [];
    ra.append("a");
    ra.append("");
    rows.append(ra);
    rb: list[str] = [];
    rb.append("b");
    rb.append("a");
    rows.append(rb);
    rc: list[str] = [];
    rc.append("c");
    rc.append("b");
    rows.append(rc);
    store = build_tree(rows);
    n = count_recursive_cte(store, "local", 20);
    assert n == 6;
}

test "diamond_walk_once_per_node" {
    rows: list[list[str]] = [];
    r1: list[str] = [];
    r1.append("a");
    r1.append("");
    rows.append(r1);
    r2: list[str] = [];
    r2.append("d");
    r2.append("c");
    rows.append(r2);
    r3: list[str] = [];
    r3.append("b");
    r3.append("a");
    rows.append(r3);
    r4: list[str] = [];
    r4.append("c");
    r4.append("a");
    rows.append(r4);
    store = build_tree(rows);
    seen = walk_tree_order(store);
    assert len(seen) == 4;
    assert seen == ["a", "b", "c", "d"];
}

test "global_partial_under_cap" {
    rows: list[list[str]] = [];
    ra: list[str] = [];
    ra.append("a");
    ra.append("");
    rows.append(ra);
    rb: list[str] = [];
    rb.append("b");
    rb.append("a");
    rows.append(rb);
    rc: list[str] = [];
    rc.append("c");
    rc.append("b");
    rows.append(rc);
    store = build_tree(rows);
    n = count_recursive_cte(store, "global", 1);
    assert n == 5;
}

test "global_raises_when_depth_exhausted" {
    rows: list[list[str]] = [];
    ra: list[str] = [];
    ra.append("a");
    ra.append("");
    rows.append(ra);
    rb: list[str] = [];
    rb.append("b");
    rb.append("a");
    rows.append(rb);
    rc: list[str] = [];
    rc.append("c");
    rc.append("b");
    rows.append(rc);
    store = build_tree(rows);
    hit = False;
    try {
        count_recursive_cte(store, "global", 5);
    } except RuntimeError {
        hit = True;
    }
    assert hit;
}

test "join_step_children_sorted" {
    rows: list[list[str]] = [];
    ra: list[str] = [];
    ra.append("a");
    ra.append("");
    rows.append(ra);
    rb: list[str] = [];
    rb.append("b");
    rb.append("a");
    rows.append(rb);
    rc: list[str] = [];
    rc.append("c");
    rc.append("a");
    rows.append(rc);
    store = build_tree(rows);
    partner: list[list] = [];
    p: list = [];
    p.append("a");
    p.append(0);
    partner.append(p);
    got = join_step(store, partner);
    keys: list[str] = [];
    for row in got {
        keys.append(row_key(row));
    }
    keys = sorted(keys);
    assert keys == ["b:1", "c:1"];
}
