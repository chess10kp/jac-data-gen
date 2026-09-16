"""Recursive CTE descendant rows — dimagi/django-cte#8."""

node GraphHub {
    has by_id: dict[str, Annotation] = {};
}

node Annotation {
    has cid: str;
    has uuid: str;
}

edge Depends {}

walker CteWalker {
    has claimed: dict[str, bool] = {};
    has rows: list[dict] = [];
    has depth: int = 0;

    can walk with Annotation entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        row: dict[str, any] = {};
        row["id"] = here.cid;
        row["uuid"] = here.uuid;
        row["depth"] = self.depth;
        self.rows.append(row);
        print([here.cid, self.depth]);
        kids: list[Annotation] = [];
        for ch in [here ->:Depends:->][?:Annotation] {
            kids.append(ch);
        }
        if kids {
            nd = self.depth + 1;
            for kid in kids {
                kid spawn CteWalker(
                    claimed=self.claimed,
                    rows=self.rows,
                    depth=nd
                );
            }
        }
        disengage;
    }
}

walker DemoWalk {
    can show with GraphHub entry {
        print(["django-cte-8", len(here.by_id)]);
        disengage;
    }
}

def make_hub -> GraphHub {
    hub = GraphHub();
    root ++> hub;
    return hub;
}

def add_annotation(hub: GraphHub, ann_id: str, uuid: str) -> Annotation {
    if ann_id in hub.by_id {
        return hub.by_id[ann_id];
    }
    nd = Annotation(cid=ann_id, uuid=uuid);
    hub ++> nd;
    hub.by_id[ann_id] = nd;
    return nd;
}

def add_dependency(hub: GraphHub, parent_id: str, child_id: str) -> bool {
    if parent_id not in hub.by_id {
        return False;
    }
    if child_id not in hub.by_id {
        return False;
    }
    parent = hub.by_id[parent_id];
    child = hub.by_id[child_id];
    parent +>:Depends:+> child;
    return True;
}

def sort_cte_rows(rows: list[dict]) -> list[dict] {
    keys: list[str] = [];
    for row in rows {
        keys.append(str(row["depth"]) + "\x00" + str(row["id"]));
    }
    sk = sorted(keys);
    out: list[dict] = [];
    for k in sk {
        for row in rows {
            rk = str(row["depth"]) + "\x00" + str(row["id"]);
            if rk == k {
                out.append(row);
            }
        }
    }
    return out;
}

def recursive_cte_rows(hub: GraphHub, root_ids: list[str]) -> list[dict] {
    rows: list[dict] = [];
    claimed: dict[str, bool] = {};
    roots: list[Annotation] = [];
    for rid in root_ids {
        if rid in hub.by_id {
            roots.append(hub.by_id[rid]);
        }
    }
    for r in roots {
        r spawn CteWalker(claimed=claimed, rows=rows, depth=0);
    }
    return sort_cte_rows(rows);
}

with entry {
    hub = make_hub();
    add_annotation(hub, "seed", "u-seed");
    recursive_cte_rows(hub, ["seed"]);
    root spawn DemoWalk();
}

test "make_hub_empty_registry" {
    hub = make_hub();
    assert len(hub.by_id) == 0;
}

test "add_annotation_idempotent" {
    hub = make_hub();
    a1 = add_annotation(hub, "a", "u-a");
    a2 = add_annotation(hub, "a", "u-other");
    assert a1 is a2;
    assert a1.uuid == "u-a";
    assert len(hub.by_id) == 1;
}

test "add_dependency_missing_returns_false" {
    hub = make_hub();
    add_annotation(hub, "p", "u-p");
    assert add_dependency(hub, "p", "missing") is False;
    assert add_dependency(hub, "missing", "p") is False;
}

test "recursive_cte_single_root" {
    hub = make_hub();
    add_annotation(hub, "seed", "u-seed");
    rows = recursive_cte_rows(hub, ["seed"]);
    assert len(rows) == 1;
    assert rows[0]["id"] == "seed";
    assert rows[0]["uuid"] == "u-seed";
    assert rows[0]["depth"] == 0;
}

test "recursive_cte_tree_sorted" {
    hub = make_hub();
    add_annotation(hub, "root", "u-root");
    add_annotation(hub, "b", "u-b");
    add_annotation(hub, "a", "u-a");
    add_dependency(hub, "root", "b");
    add_dependency(hub, "root", "a");
    rows = recursive_cte_rows(hub, ["root"]);
    assert len(rows) == 3;
    ids: list[str] = [];
    for row in rows {
        ids.append(str(row["id"]));
    }
    assert ids == ["root", "a", "b"];
    depths: list[int] = [];
    for row in rows {
        depths.append(row["depth"]);
    }
    assert depths == [0, 1, 1];
}

test "recursive_cte_cycle_once_only" {
    hub = make_hub();
    add_annotation(hub, "x", "u-x");
    add_annotation(hub, "y", "u-y");
    add_dependency(hub, "x", "y");
    add_dependency(hub, "y", "x");
    rows = recursive_cte_rows(hub, ["x"]);
    assert len(rows) == 2;
    ids: list[str] = [];
    for row in rows {
        ids.append(str(row["id"]));
    }
    assert sorted(ids) == ["x", "y"];
}
