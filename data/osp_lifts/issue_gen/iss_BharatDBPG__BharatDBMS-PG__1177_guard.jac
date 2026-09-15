"""BharatDBPG/BharatDBMS-PG#1177 — BFS depth tuples (SEARCH BREADTH FIRST *DEPTH* access)."""

node TreeNode {
    has nid: int;
    has name: str;
    has parent_id: int = -1;
    has depth: int = -1;
}

edge ParentChild {}

walker BfsRows {
    has claimed: dict[str, bool] = {};
    has out_rows: list = [];

    can walk with TreeNode entry {
        cid = str(here.nid);
        if cid in self.claimed {
            skip;
        }
        self.claimed[cid] = True;
        row = (here.depth, here.nid, here.name);
        self.out_rows.append(row);
        kids: list[TreeNode] = [here ->:ParentChild:->][?:TreeNode];
        nd = here.depth + 1;
        for kid in kids {
            kid.depth = nd;
            visit [kid];
        }
        print("bfs", here.nid, here.depth);
    }
}

def make_store(rows: list) -> dict[str, TreeNode] {
    store: dict[str, TreeNode] = {};
    for row in rows {
        nid = row[0];
        pid = row[1];
        nm = row[2];
        pval = -1;
        if pid >= 0 {
            pval = pid;
        }
        nd = TreeNode(nid=nid, name=nm, parent_id=pval);
        root ++> nd;
        store[str(nid)] = nd;
    }
    for row in rows {
        nid = row[0];
        pid = row[1];
        if pid >= 0 {
            store[str(pid)] +>:ParentChild:+> store[str(nid)];
        }
    }
    return store;
}

def bfs_depth_tuples(store: dict[str, TreeNode], root_id: int) -> list {
    rid = str(root_id);
    if rid not in store {
        return [];
    }
    graph_root = store[rid];
    graph_root.depth = 0;
    out_rows: list = [];
    claimed: dict[str, bool] = {};
    w = graph_root spawn BfsRows(claimed=claimed, out_rows=out_rows);
    return out_rows;
}

def tuple_depth(row: tuple) -> int {
    return row[0];
}

def depth_dict_row(row: tuple) -> dict {
    out: dict = {};
    out["depth"] = row[0];
    out["id"] = row[1];
    out["name"] = row[2];
    return out;
}

def ids_at_depth(store: dict[str, TreeNode], root_id: int, depth: int) -> list[int] {
    rows = bfs_depth_tuples(store, root_id);
    out: list[int] = [];
    for row in rows {
        if tuple_depth(row) == depth {
            out.append(row[1]);
        }
    }
    out.sort();
    return out;
}

def bfs_json_rows(store: dict[str, TreeNode], root_id: int) -> list {
    rows = bfs_depth_tuples(store, root_id);
    out: list = [];
    for row in rows {
        out.append(depth_dict_row(row));
    }
    return out;
}

test "depth_zero_root_only" {
    store = make_store([(1, -1, "root")]);
    assert ids_at_depth(store, 1, 0) == [1];
}

test "ids_at_depth_level_one_sorted" {
    store = make_store([(1, -1, "r"), (3, 1, "c"), (2, 1, "b")]);
    assert ids_at_depth(store, 1, 1) == [2, 3];
}

test "tuple_depth_first_field" {
    store = make_store([(1, -1, "r"), (2, 1, "a")]);
    rows = bfs_depth_tuples(store, 1);
    assert tuple_depth(rows[0]) == 0;
    assert tuple_depth(rows[1]) == 1;
}

test "bfs_json_rows_fields" {
    store = make_store([(1, -1, "root")]);
    js = bfs_json_rows(store, 1);
    assert js[0]["depth"] == 0;
    assert js[0]["id"] == 1;
    assert js[0]["name"] == "root";
}

test "missing_root_returns_empty" {
    store = make_store([(1, -1, "r")]);
    assert bfs_depth_tuples(store, 99) == [];
}

test "depth_dict_row_shape" {
    row = (2, 5, "n");
    d = depth_dict_row(row);
    assert d["depth"] == 2;
    assert d["id"] == 5;
    assert d["name"] == "n";
}
