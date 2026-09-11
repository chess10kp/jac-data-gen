"""advplyr/audiobookshelf#5452 — nested collection parentId hierarchy."""

node Collection {
    has cid: str;
    has library_id: str;
    has name: str;
    has book_ids: list[str] = [];
}

edge ChildOf: Collection --> Collection {}

obj CollectionLibrary {
    has collections: dict[str, dict] = {};
}

walker DescCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Collection entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.origin { self.found.append(here.cid); }
        visit [here ->:ChildOf:->][?:Collection];
    }
}

def _find_collection(collection_id: str) -> Collection | None {
    for nd in [root-->[?:Collection]] {
        if nd.cid == collection_id { return nd; }
    }
    return None;
}

def load_collection_library(records: list[dict]) -> CollectionLibrary {
    lib = CollectionLibrary();
    for rec in records {
        cid = str(rec["id"]);
        raw_books = rec.get("books", []);
        book_ids: list[str] = [];
        if isinstance(raw_books, list) {
            for b in raw_books { book_ids.append(str(b)); }
        }
        lib.collections[cid] = {
            "library_id": str(rec["library_id"]),
            "name": str(rec["name"]),
            "parent_id": rec.get("parent_id", None),
            "books": book_ids,
        };
        nd = Collection(
            cid=cid,
            library_id=str(rec["library_id"]),
            name=str(rec["name"]),
            book_ids=book_ids,
        );
        root ++> nd;
    }
    for cid in lib.collections.keys() {
        row = lib.collections[cid];
        parent_id = row.get("parent_id", None);
        if parent_id is not None and parent_id in lib.collections {
            par = _find_collection(str(parent_id));
            ch = _find_collection(cid);
            if par is not None and ch is not None {
                par +>:ChildOf:+> ch;
            }
        }
    }
    return lib;
}

def list_root_collections(lib: CollectionLibrary, library_id: str) -> list[str] {
    out: list[str] = [];
    for cid in lib.collections.keys() {
        row = lib.collections[cid];
        if row["library_id"] == library_id and row.get("parent_id", None) is None {
            out.append(cid);
        }
    }
    return sorted(out);
}

def child_collections(lib: CollectionLibrary, parent_id: str) -> list[str] {
    if not (parent_id in lib.collections) { return []; }
    par = _find_collection(parent_id);
    if par is None { return []; }
    out: list[str] = [];
    for ch in [par ->:ChildOf:->][?:Collection] {
        out.append(ch.cid);
    }
    return sorted(out);
}

def breadcrumb(lib: CollectionLibrary, collection_id: str) -> list[str] {
    if not (collection_id in lib.collections) { return []; }
    chain: list[str] = [];
    cur: str | None = collection_id;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur in seen { break; }
        seen[cur] = True;
        chain.append(str(lib.collections[cur]["name"]));
        row = lib.collections.get(cur, None);
        if row is None { cur = None; }
        else { cur = row.get("parent_id", None); }
    }
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

def descendant_collections(lib: CollectionLibrary, root_id: str) -> list[str] {
    if not (root_id in lib.collections) { return []; }
    nd = _find_collection(root_id);
    if nd is None { return []; }
    w = nd spawn DescCollect(claimed={}, found=[], origin=root_id);
    return sorted(w.found);
}

def would_create_cycle(
    lib: CollectionLibrary, child_id: str, new_parent_id: str
) -> bool {
    if not (child_id in lib.collections) or not (new_parent_id in lib.collections) {
        return False;
    }
    if child_id == new_parent_id { return True; }
    cur: str | None = new_parent_id;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur == child_id { return True; }
        if cur in seen { return True; }
        seen[cur] = True;
        row = lib.collections.get(cur, None);
        if row is None { cur = None; }
        else { cur = row.get("parent_id", None); }
    }
    return False;
}

def set_parent(
    lib: CollectionLibrary, child_id: str, parent_id: str | None
) -> None {
    if not (child_id in lib.collections) { raise KeyError(child_id); }
    if parent_id is not None {
        if not (parent_id in lib.collections) { raise KeyError(parent_id); }
        if child_id == parent_id {
            raise ValueError("collection cannot be its own parent");
        }
        child_lib = lib.collections[child_id]["library_id"];
        parent_lib = lib.collections[parent_id]["library_id"];
        if child_lib != parent_lib {
            raise ValueError("parent and child must belong to the same library");
        }
        if would_create_cycle(lib, child_id, parent_id) {
            raise ValueError("parent assignment would create cycle");
        }
    }
    old_parent = lib.collections[child_id].get("parent_id", None);
    child_nd = _find_collection(child_id);
    if old_parent is not None {
        old_par_nd = _find_collection(str(old_parent));
        if old_par_nd is not None and child_nd is not None {
            old_par_nd del ->:ChildOf:-> child_nd;
        }
    }
    lib.collections[child_id]["parent_id"] = parent_id;
    if parent_id is not None {
        new_par_nd = _find_collection(parent_id);
        if new_par_nd is not None and child_nd is not None {
            new_par_nd +>:ChildOf:+> child_nd;
        }
    }
}

def delete_collection(lib: CollectionLibrary, collection_id: str) -> list[str] {
    if not (collection_id in lib.collections) { raise KeyError(collection_id); }
    reparented: list[str] = [];
    del_nd = _find_collection(collection_id);
    if del_nd is not None {
        for ch in [del_nd ->:ChildOf:->][?:Collection] {
            lib.collections[ch.cid]["parent_id"] = None;
            reparented.append(ch.cid);
            del_nd del ->:ChildOf:-> ch;
        }
    }
    old_parent = lib.collections[collection_id].get("parent_id", None);
    if old_parent is not None {
        old_par_nd = _find_collection(str(old_parent));
        if old_par_nd is not None and del_nd is not None {
            old_par_nd del ->:ChildOf:-> del_nd;
        }
    }
    if del_nd is not None { del del_nd; }
    lib.collections.__delitem__(collection_id);
    return sorted(reparented);
}

test "cycle descendant claim map skips revisit without disengage" {
    lib = load_collection_library([
        {"id": "c", "library_id": "cyc", "name": "C", "parent_id": "b", "books": []},
        {"id": "a", "library_id": "cyc", "name": "A", "parent_id": "c", "books": []},
        {"id": "b", "library_id": "cyc", "name": "B", "parent_id": "a", "books": []},
    ]);
    assert descendant_collections(lib, "a") == ["b", "c"];;
    assert descendant_collections(lib, "b") == ["a", "c"];;
    assert descendant_collections(lib, "c") == ["a", "b"];;
}

test "unknown id tolerance across hierarchy queries" {
    lib = load_collection_library([
        {"id": "solo", "library_id": "lib", "name": "Solo", "parent_id": None, "books": []},
        {"id": "waif", "library_id": "lib", "name": "Waif", "parent_id": "absent", "books": []},
    ]);
    assert list_root_collections(lib, "ghost") == [];;
    assert child_collections(lib, "ghost") == [];;
    assert breadcrumb(lib, "ghost") == [];;
    assert descendant_collections(lib, "ghost") == [];;
    assert would_create_cycle(lib, "ghost", "solo") == False;;
    assert would_create_cycle(lib, "solo", "ghost") == False;;
    assert child_collections(lib, "absent") == [];;
    assert list_root_collections(lib, "lib") == ["solo"];;
    assert child_collections(lib, "solo") == [];;
}

test "set_parent detach and unknown parent KeyError" {
    lib = load_collection_library([
        {"id": "dnd", "library_id": "main", "name": "Dungeons & Dragons", "parent_id": None, "books": []},
        {"id": "adv", "library_id": "main", "name": "Adventures", "parent_id": "dnd", "books": []},
        {"id": "exp", "library_id": "main", "name": "Expansions", "parent_id": "dnd", "books": []},
    ]);
    set_parent(lib, "adv", None);
    assert list_root_collections(lib, "main") == ["adv", "dnd"];;
    assert child_collections(lib, "dnd") == ["exp"];;
    assert breadcrumb(lib, "adv") == ["Adventures"];;
    raised = False;
    try {
        set_parent(lib, "exp", "missing");
        assert False, "should have raised";
    } except KeyError {
        raised = True;
    }
    assert raised;;
}

test "delete promotes only direct children grandchildren stay nested" {
    lib = load_collection_library([
        {"id": "sw", "library_id": "main", "name": "Star Wars", "parent_id": None, "books": []},
        {"id": "canon", "library_id": "main", "name": "Canon", "parent_id": "sw", "books": []},
        {"id": "hr", "library_id": "main", "name": "High Republic", "parent_id": "canon", "books": []},
        {"id": "legends", "library_id": "main", "name": "Legends", "parent_id": "sw", "books": []},
    ]);
    assert delete_collection(lib, "sw") == ["canon", "legends"];;
    assert list_root_collections(lib, "main") == ["canon", "legends"];;
    assert lib.collections["canon"]["parent_id"] is None;;
    assert lib.collections["hr"]["parent_id"] == "canon";;
    assert child_collections(lib, "canon") == ["hr"];;
    assert descendant_collections(lib, "canon") == ["hr"];;
    assert breadcrumb(lib, "hr") == ["Canon", "High Republic"];;
}

test "adversarial load order wide fan-out descendant closure" {
    lib = load_collection_library([
        {"id": "leaf_z", "library_id": "main", "name": "Leaf Z", "parent_id": "branch_z", "books": []},
        {"id": "leaf_y", "library_id": "main", "name": "Leaf Y", "parent_id": "branch_y", "books": []},
        {"id": "leaf_x", "library_id": "main", "name": "Leaf X", "parent_id": "branch_x", "books": []},
        {"id": "branch_z", "library_id": "main", "name": "Branch Z", "parent_id": "hub", "books": []},
        {"id": "branch_y", "library_id": "main", "name": "Branch Y", "parent_id": "hub", "books": []},
        {"id": "branch_x", "library_id": "main", "name": "Branch X", "parent_id": "hub", "books": []},
        {"id": "hub", "library_id": "main", "name": "Hub", "parent_id": None, "books": []},
    ]);
    assert descendant_collections(lib, "hub") == [
        "branch_x",
        "branch_y",
        "branch_z",
        "leaf_x",
        "leaf_y",
        "leaf_z",
    ];;
    assert child_collections(lib, "hub") == ["branch_x", "branch_y", "branch_z"];;
}

test "breadcrumb breaks on corrupt parent cycle" {
    lib = load_collection_library([
        {"id": "a", "library_id": "cyc", "name": "Alpha", "parent_id": "c", "books": []},
        {"id": "b", "library_id": "cyc", "name": "Beta", "parent_id": "a", "books": []},
        {"id": "c", "library_id": "cyc", "name": "Gamma", "parent_id": "b", "books": []},
    ]);
    assert breadcrumb(lib, "a") == ["Beta", "Gamma", "Alpha"];;
    assert would_create_cycle(lib, "b", "a") == True;;
}
