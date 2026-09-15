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
