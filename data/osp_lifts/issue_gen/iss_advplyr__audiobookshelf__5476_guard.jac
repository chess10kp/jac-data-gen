"""advplyr/audiobookshelf#5476 — paginated relational Collection read API."""

node Collection {
    has cid: str;
    has library_id: str;
    has name: str;
    has book_ids: list[str] = [];
}

edge ChildOf: Collection --> Collection {}

obj CollectionStore {
    has collections: dict[str, dict] = {};
    has books: dict[str, dict] = {};
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

def _coll_name_key(row: dict) -> str {
    return str(row["name"]).casefold();
}

def build_store(
    collection_rows: list[dict],
    book_rows: list[dict],
) -> CollectionStore {
    store = CollectionStore();
    for row in book_rows {
        tg: set[str] = set();
        raw_tags = row.get("tags", []);
        if isinstance(raw_tags, list) {
            for t in raw_tags { tg.add(str(t)); }
        }
        store.books[str(row["id"])] = {
            "explicit": bool(row.get("explicit", False)),
            "tags": tg,
        };
    }
    for row in collection_rows {
        cid = str(row["id"]);
        raw_books = row.get("books", []);
        book_ids: list[str] = [];
        if isinstance(raw_books, list) {
            for b in raw_books { book_ids.append(str(b)); }
        }
        store.collections[cid] = {
            "library_id": str(row["library_id"]),
            "name": str(row["name"]),
            "parent_id": row.get("parent_id", None),
            "book_ids": book_ids,
        };
        root ++> Collection(
            cid=cid,
            library_id=str(row["library_id"]),
            name=str(row["name"]),
            book_ids=book_ids,
        );
    }
    for cid in store.collections.keys() {
        row = store.collections[cid];
        parent_id = row.get("parent_id", None);
        if parent_id is not None and parent_id in store.collections {
            par = _find_collection(str(parent_id));
            ch = _find_collection(cid);
            if par is not None and ch is not None { par +>:ChildOf:+> ch; }
        }
    }
    return store;
}

def _book_visible(
    book_id: str,
    store: CollectionStore,
    user_tags: set[str],
    allow_explicit: bool,
) -> bool {
    meta = store.books.get(book_id, None);
    if meta is None { return False; }
    if meta["explicit"] and not allow_explicit { return False; }
    if len(user_tags) > 0 {
        tags = meta["tags"] as set[str];
        hit = False;
        for t in tags {
            if t in user_tags { hit = True; }
        }
        if not hit { return False; }
    }
    return True;
}

def accessible_books(
    store: CollectionStore,
    collection_id: str,
    user_tags: set[str],
    allow_explicit: bool,
) -> list[str] {
    if not (collection_id in store.collections) { return []; }
    book_ids: list[str] = store.collections[collection_id]["book_ids"] as list[str];
    out: list[str] = [];
    for bid in book_ids {
        if _book_visible(bid, store, user_tags, allow_explicit) { out.append(bid); }
    }
    return sorted(out);
}

def ancestor_ids(store: CollectionStore, collection_id: str) -> list[str] {
    if not (collection_id in store.collections) { return []; }
    chain: list[str] = [];
    cur = store.collections[collection_id].get("parent_id", None);
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur in seen { break; }
        seen[cur] = True;
        chain.append(str(cur));
        nxt = store.collections.get(str(cur), None);
        if nxt is None { cur = None; }
        else { cur = nxt.get("parent_id", None); }
    }
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

def descendant_ids(store: CollectionStore, root_id: str) -> list[str] {
    if not (root_id in store.collections) { return []; }
    nd = _find_collection(root_id);
    if nd is None { return []; }
    w = nd spawn DescCollect(claimed={}, found=[], origin=root_id);
    return sorted(w.found);
}

def paginate_collections(
    store: CollectionStore,
    library_id: str,
    user_tags: set[str],
    allow_explicit: bool,
    *,
    page: int = 0,
    limit: int = 20,
    sort_key: str = "name",
    descending: bool = False,
    name_filter: str = "",
    preview_limit: int = 2,
) -> dict {
    needle = name_filter.casefold();
    rows: list[dict] = [];
    for cid in store.collections.keys() {
        col = store.collections[cid];
        if col["library_id"] != library_id { continue; }
        if needle and needle not in str(col["name"]).casefold() { continue; }
        visible = accessible_books(store, cid, user_tags, allow_explicit);
        rows.append({"name": str(col["name"]), "cid": cid, "visible": visible});
    }
    if sort_key == "name" {
        rows = sorted(rows, key=_coll_name_key, reverse=descending);
    } else {
        rows = sorted(rows, key=_coll_name_key);
    }
    start = page * limit;
    end = start + limit;
    page_rows: list[dict] = [];
    for i in range(start, end) {
        if i < len(rows) { page_rows.append(rows[i]); }
    }
    results: list[dict] = [];
    for row in page_rows {
        cid = str(row["cid"]);
        visible = row["visible"] as list[str];
        col = store.collections[cid];
        previews: list[dict] = [];
        for j in range(min(preview_limit, len(visible))) {
            previews.append({"id": visible[j]});
        }
        results.append({
            "id": cid,
            "libraryId": col["library_id"],
            "name": str(row["name"]),
            "parentId": col.get("parent_id", None),
            "numBooks": len(visible),
            "previewItems": previews,
        });
    }
    return {"total": len(rows), "results": results};
}

test "permission filtered accessible books and unknown collection" {
    fantasy: set[str] = set();
    fantasy.add("fantasy");
    scifi: set[str] = set();
    scifi.add("scifi");
    store = build_store(
        [
            {"id": "dnd", "library_id": "main", "name": "Dungeons & Dragons", "parent_id": None, "books": ["b1", "b2", "b3"]},
            {"id": "sw", "library_id": "main", "name": "Star Wars", "parent_id": None, "books": ["b5"]},
            {"id": "canon", "library_id": "main", "name": "Canon", "parent_id": "sw", "books": ["b6"]},
        ],
        [
            {"id": "b1", "explicit": False, "tags": ["fantasy"]},
            {"id": "b2", "explicit": False, "tags": ["fantasy", "core"]},
            {"id": "b3", "explicit": True, "tags": ["fantasy"]},
            {"id": "b5", "explicit": True, "tags": ["scifi"]},
            {"id": "b6", "explicit": False, "tags": ["scifi"]},
        ],
    );
    assert accessible_books(store, "dnd", fantasy, False) == ["b1", "b2"];
    assert accessible_books(store, "dnd", fantasy, True) == ["b1", "b2", "b3"];
    assert accessible_books(store, "sw", scifi, False) == [];
    assert accessible_books(store, "canon", scifi, False) == ["b6"];
    assert accessible_books(store, "missing", fantasy, False) == [];
}

test "ancestor and descendant ids on main library tree" {
    store = build_store(
        [
            {"id": "dnd", "library_id": "main", "name": "Dungeons & Dragons", "parent_id": None, "books": []},
            {"id": "adv", "library_id": "main", "name": "Adventures", "parent_id": "dnd", "books": []},
            {"id": "sw", "library_id": "main", "name": "Star Wars", "parent_id": None, "books": []},
            {"id": "canon", "library_id": "main", "name": "Canon", "parent_id": "sw", "books": []},
        ],
        [],
    );
    assert ancestor_ids(store, "canon") == ["sw"];
    assert ancestor_ids(store, "adv") == ["dnd"];
    assert ancestor_ids(store, "dnd") == [];
    assert descendant_ids(store, "sw") == ["canon"];
    assert descendant_ids(store, "dnd") == ["adv"];
    assert ancestor_ids(store, "missing") == [];
    assert descendant_ids(store, "missing") == [];
}

test "paginate collections page slice filter and descending sort" {
    fantasy: set[str] = set();
    fantasy.add("fantasy");
    scifi: set[str] = set();
    scifi.add("scifi");
    store = build_store(
        [
            {"id": "dnd", "library_id": "main", "name": "Dungeons & Dragons", "parent_id": None, "books": ["b1", "b2", "b3"]},
            {"id": "adv", "library_id": "main", "name": "Adventures", "parent_id": "dnd", "books": ["b4"]},
            {"id": "sw", "library_id": "main", "name": "Star Wars", "parent_id": None, "books": ["b5"]},
            {"id": "canon", "library_id": "main", "name": "Canon", "parent_id": "sw", "books": ["b6"]},
        ],
        [
            {"id": "b1", "explicit": False, "tags": ["fantasy"]},
            {"id": "b2", "explicit": False, "tags": ["fantasy"]},
            {"id": "b3", "explicit": True, "tags": ["fantasy"]},
            {"id": "b4", "explicit": False, "tags": ["fantasy"]},
            {"id": "b5", "explicit": True, "tags": ["scifi"]},
            {"id": "b6", "explicit": False, "tags": ["scifi"]},
        ],
    );
    page0 = paginate_collections(store, "main", fantasy, False, page=0, limit=2, preview_limit=2);
    assert page0["total"] == 4;
    assert [row["id"] for row in page0["results"]] == ["adv", "canon"];
    assert page0["results"][0]["previewItems"] == [{"id": "b4"}];
    page1 = paginate_collections(store, "main", fantasy, False, page=1, limit=2, preview_limit=2);
    assert [row["id"] for row in page1["results"]] == ["dnd", "sw"];
    assert page1["results"][0]["previewItems"] == [{"id": "b1"}, {"id": "b2"}];
    filtered = paginate_collections(store, "main", scifi, False, name_filter="can", preview_limit=1);
    assert filtered["total"] == 1;
    assert [row["id"] for row in filtered["results"]] == ["canon"];
    desc = paginate_collections(store, "main", fantasy, False, descending=True, preview_limit=1);
    assert [row["name"] for row in desc["results"]] == [
        "Star Wars",
        "Dungeons & Dragons",
        "Canon",
        "Adventures",
    ];
}

test "unknown library paginate returns empty page" {
    fantasy: set[str] = set();
    fantasy.add("fantasy");
    store = build_store([], []);
    assert paginate_collections(store, "missing", fantasy, False) == {"total": 0, "results": []};
}

test "cycle descendant revisit adversarial edge insertion order" {
    cyc = build_store(
        [
            {"id": "c", "library_id": "cyc", "name": "C", "parent_id": "b", "books": []},
            {"id": "a", "library_id": "cyc", "name": "A", "parent_id": "c", "books": []},
            {"id": "b", "library_id": "cyc", "name": "B", "parent_id": "a", "books": []},
        ],
        [],
    );
    assert descendant_ids(cyc, "a") == ["b", "c"];
    assert ancestor_ids(cyc, "b") == ["b", "c", "a"];
}
