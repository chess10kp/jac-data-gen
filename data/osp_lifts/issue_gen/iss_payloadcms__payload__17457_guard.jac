"""payloadcms/payload#17457 — nested-docs resaveChildren cascade + silent rollback."""

node Page {
    has cid: str;
    has title: str;
    has updated_at: int = 0;
    has valid: bool = True;
    has path: str = "";
}

edge ParentOf {}

obj NestedDocStore {
    has nodes: dict[str, Page] = {};
}

walker CollectResave {
    has claimed: dict[str, bool] = {};
    has order: list[str] = {};

    can step with Page entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print ["visit", here.cid];
        kids: list[Page] = [];
        for ch in [here ->:ParentOf:->][?:Page] {
            kids.append(ch);
        }
        cid_list: list[str] = [];
        for k in kids {
            cid_list.append(k.cid);
        }
        cid_list = sorted(cid_list);
        skids: list[Page] = [];
        for cid in cid_list {
            for k in kids {
                if k.cid == cid {
                    skids.append(k);
                }
            }
        }
        if skids {
            idx: int = len(skids) - 1;
            while idx >= 0 {
                visit :0: [skids[idx]];
                idx -= 1;
            }
        } else {
            disengage;
        }
    }
}

def build_store(rows: list[dict[str, any]]) -> NestedDocStore {
    store = NestedDocStore();
    pending: list[dict[str, any]] = [];
    id_map: dict[str, Page] = {};
    for row in rows {
        ts: int = 0;
        if "updated_at" in row {
            ts = row["updated_at"];
        }
        ok: bool = True;
        if "valid" in row {
            ok = row["valid"];
        }
        pth: str = row["title"];
        if "path" in row {
            pth = row["path"];
        }
        pg = Page(cid=row["id"], title=row["title"], updated_at=ts, valid=ok, path=pth);
        id_map[row["id"]] = pg;
        root ++> pg;
        if "parent" in row {
            pending.append(row);
        }
    }
    for row in pending {
        if row["parent"] in id_map {
            par = id_map[row["parent"]];
            ch = id_map[row["id"]];
            par +>:ParentOf:+> ch;
        }
    }
    store.nodes = id_map;
    return store;
}

def get_page(store: NestedDocStore, page_id: str) -> dict[str, any] | None {
    if page_id not in store.nodes {
        return None;
    }
    pg = store.nodes[page_id];
    return {
        "id": pg.cid,
        "title": pg.title,
        "updated_at": pg.updated_at,
        "valid": pg.valid,
        "path": pg.path,
    };
}

def resave_children_order(store: NestedDocStore, parent_id: str) -> list[str] {
    if parent_id not in store.nodes {
        return [];
    }
    anchor = store.nodes[parent_id];
    w = anchor spawn CollectResave(claimed={});
    print ["order", w.order];
    return w.order;
}

def update_parent(store: NestedDocStore, parent_id: str, title: str) -> dict[str, any] {
    if parent_id not in store.nodes {
        return {"ok": False, "updated_at": 0, "persisted": False, "error": "unknown_id"};
    }
    parent = store.nodes[parent_id];
    old_ts = parent.updated_at;
    order = resave_children_order(store, parent_id);
    child_err: str = "";
    for cid in order {
        if cid == parent_id {
            continue;
        }
        ch = store.nodes[cid];
        if not ch.valid {
            child_err = "validation:" + cid;
            break;
        }
    }
    new_ts: int = old_ts + 1;
    if child_err {
        print ["rollback", parent_id, child_err];
        return {"ok": True, "updated_at": new_ts, "persisted": False, "error": child_err};
    }
    parent.title = title;
    parent.updated_at = new_ts;
    for cid in order {
        if cid == parent_id {
            continue;
        }
        ch = store.nodes[cid];
        ch.path = parent.path + "/" + ch.title;
        ch.updated_at = new_ts;
    }
    print ["persisted", parent_id, new_ts];
    return {"ok": True, "updated_at": new_ts, "persisted": True, "error": ""};
}

test "unknown_parent_update" {
    rows: list[dict[str, any]] = [{"id": "p", "title": "Root", "path": "/root", "updated_at": 1}];
    store = build_store(rows);
    out = update_parent(store, "missing", "X");
    assert (out["ok"] == False);
    assert (out["persisted"] == False);
    assert (out["error"] == "unknown_id");
}

test "resave_order_dfs_sorted" {
    rows: list[dict[str, any]] = [
        {"id": "p", "title": "P", "path": "/p", "updated_at": 0},
        {"id": "a", "title": "A", "parent": "p", "valid": True},
        {"id": "b", "title": "B", "parent": "p", "valid": True},
        {"id": "c", "title": "C", "parent": "a", "valid": True},
    ];
    store = build_store(rows);
    order = resave_children_order(store, "p");
    assert (order == ["p", "c", "a", "b"]);
}

test "validation_rollback_silent" {
    rows: list[dict[str, any]] = [
        {"id": "p", "title": "Old", "path": "/p", "updated_at": 3},
        {"id": "ok", "title": "Good", "parent": "p", "valid": True, "path": "/p/Good"},
        {"id": "bad", "title": "Bad", "parent": "p", "valid": False, "path": "/p/Bad"},
    ];
    store = build_store(rows);
    out = update_parent(store, "p", "New");
    pg = get_page(store, "p");
    assert (out["ok"] == True);
    assert (out["persisted"] == False);
    assert (out["updated_at"] == 4);
    assert (out["error"] == "validation:bad");
    assert (pg["title"] == "Old");
    assert (pg["updated_at"] == 3);
}

test "success_cascade_paths" {
    rows: list[dict[str, any]] = [
        {"id": "p", "title": "Root", "path": "/root", "updated_at": 1},
        {"id": "x", "title": "X", "parent": "p", "valid": True, "path": "/root/X"},
        {"id": "y", "title": "Y", "parent": "x", "valid": True, "path": "/root/X/Y"},
    ];
    store = build_store(rows);
    out = update_parent(store, "p", "Root2");
    px = get_page(store, "p");
    py = get_page(store, "y");
    assert (out["ok"] == True);
    assert (out["persisted"] == True);
    assert (out["updated_at"] == 2);
    assert (px["title"] == "Root2");
    assert (px["updated_at"] == 2);
    assert (py["path"] == "/root/X/Y");
    assert (py["updated_at"] == 2);
}

test "get_page_missing" {
    rows: list[dict[str, any]] = [{"id": "p", "title": "P", "path": "/p", "updated_at": 0}];
    store = build_store(rows);
    got = get_page(store, "nope");
    assert (got is None);
}
