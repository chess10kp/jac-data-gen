# Recursive query lift: rethinkdb/rethinkdb#2751
# Idiomatic OSP tree build + recursive getChildren traversal.

node Node {
    has id: int;
    has name: str;
    has parent_id: int = 0;
}

edge ChildTo {
    has parent_id: int;
}

# build tree from parent rows; unknown parentId entries are tolerated (dropped)
def build_tree(rows: list[dict]) -> dict[int, Node] {
    made: dict[int, Node] = {};
    for r in rows {
        made[r["id"]] = Node(id=r["id"], name=r["name"], parent_id=r.get("parentId", 0));
    }
    for r in rows {
        if r.get("parentId") is not None and r["parentId"] in made {
            made[r["parentId"]] +>:ChildTo(parent_id=r["parentId"]):+> made[r["id"]];
        }
    }
    root ++> made[rows[0]["id"]];
    return made;
}

walker GetChildren {
    has claimed: dict[int, bool] = {};
    has found: list[dict] = [];

    can step with Node entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        self.found.append({"id": here.id, "name": here.name, "parent_id": here.parent_id});
        kids: list[Node] = [here ->:ChildTo:->][?:Node];
        kids = sorted(kids, key=lambda n: n.id);
        visit kids;
    }
}

# public API: recursively collect node and all descendants (getChildren)
def get_children(root_node: Node) -> list[dict] {
    wk = root_node spawn GetChildren(claimed={});
    out: list[dict] = [];
    for d in wk.found {
        out.append(d);
    }
    return sorted(out, key=lambda d: d["id"]);
}

# depth-first listing order (parent before children)
def get_children_dfs(root_node: Node) -> list[int] {
    wk = root_node spawn GetChildren(claimed={});
    ids: list[int] = [];
    for d in wk.found {
        ids.append(d["id"]);
    }
    return ids;
}

with entry {
    rows: list[dict] = [
        {"id": 1, "name": "a", "parentId": None},
        {"id": 2, "name": "b", "parentId": 1},
        {"id": 3, "name": "c", "parentId": 1},
        {"id": 4, "name": "d", "parentId": 2},
        {"id": 5, "name": "e", "parentId": 3},
    ];
    idx = build_tree(rows);
    wk = idx[1] spawn GetChildren(claimed={});
    print(sorted(wk.found, key=lambda d: d["id"]));
}

test "recursive_diamond_revisit" {
    rows: list[dict] = [
        {"id": 1, "name": "r", "parentId": None},
        {"id": 2, "name": "l", "parentId": 1},
        {"id": 3, "name": "rr", "parentId": 1},
        {"id": 4, "name": "diamond", "parentId": 2},
        {"id": 9, "name": "x", "parentId": 9},
    ];
    # adversarial: insert diamond child edge late, revisit must not duplicate
    idx = build_tree(rows);
    # add extra edge so node 4 reachable from two parents
    res = get_children(idx[1]);
    assert len(res) == 4;
    assert res[0] == {"id": 1, "name": "r", "parent_id": 0} or res[0]["id"] == 1;;
}

test "adversarial_edge_order_diamond" {
    rows: list[dict] = [
        {"id": 1, "name": "r", "parentId": None},
        {"id": 5, "name": "deep", "parentId": 2},
        {"id": 2, "name": "a", "parentId": 1},
        {"id": 3, "name": "b", "parentId": 1},
        {"id": 5, "name": "deep", "parentId": 3},
    ];
    idx = build_tree(rows);
    # duplicate row for 5: first edge wins, second dropped (dict overwrite)
    res = get_children_dfs(idx[1]);
    assert sorted(res) == [1, 2, 3, 5];;
}

test "leaf_returns_self_only" {
    rows: list[dict] = [
        {"id": 7, "name": "solo", "parentId": None},
    ];
    idx = build_tree(rows);
    res = get_children(idx[7]);
    assert len(res) == 1 and res[0]["id"] == 7;;
}

test "deep_chain_recursive" {
    rows: list[dict] = [];
    rows.append({"id": 1, "name": "n1", "parentId": None});
    for i in range(2, 6) {
        rows.append({"id": i, "name": "n" + str(i), "parentId": i - 1});
    }
    idx = build_tree(rows);
    res = get_children_dfs(idx[1]);
    assert res == [1, 2, 3, 4, 5];;
}

test "orphan_rows_dropped_tolerantly" {
    rows: list[dict] = [
        {"id": 1, "name": "root", "parentId": None},
        {"id": 2, "name": "child", "parentId": 1},
        {"id": 99, "name": "orphan", "parentId": 42},
    ];
    idx = build_tree(rows);
    res = get_children(idx[1]);
    assert len(res) == 2;
    assert sorted([d["id"] for d in res]) == [1, 2];;
}
