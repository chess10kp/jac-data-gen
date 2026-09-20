"""sgaunet/s3xplorer#79 — batch parent folder creation (N+1 elimination)."""

node FolderStore {
    has existing: dict[str, bool] = {};
}

node PathRoot {
    has bucket_id: str;
    has object_key: str;
}

node Segment {
    has part: str;
    has depth: int;
    has folder_key: str;
    has sid: str;
}

edge seg_next {}

walker ParentRowCollector {
    has claimed: dict[str, bool] = {};
    has bucket_id: str = "";
    has rows: list[dict] = {};

    can anchor_entry with PathRoot entry {
        rk = here.object_key;
        if rk in self.claimed {
            skip;
        }
        self.claimed[rk] = True;
        self.bucket_id = here.bucket_id;
        print here.object_key;
        kids: list[Segment] = [here ->:seg_next:->][?:Segment];
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }

    can seg_entry with Segment entry {
        sid = here.sid;
        if sid in self.claimed {
            skip;
        }
        self.claimed[sid] = True;
        row: dict[str, str | int] = {};
        row["bucket_id"] = self.bucket_id;
        row["key"] = here.folder_key;
        row["prefix"] = folder_prefix(here.folder_key);
        row["depth"] = here.depth;
        self.rows.append(row);
        print here.folder_key;
        nxt: list[Segment] = [here ->:seg_next:->][?:Segment];
        if len(nxt) > 0 {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

def split_object_key(object_key: str) -> list[str] {
    parts: list[str] = [];
    if object_key == "" {
        return parts;
    }
    token: str = "";
    for ch in object_key {
        if ch == "/" {
            if token != "" {
                parts.append(token);
                token = "";
            }
        } else {
            token = token + ch;
        }
    }
    if token != "" {
        parts.append(token);
    }
    return parts;
}

def folder_prefix(folder_key: str) -> str {
    parts: list[str] = split_object_key(folder_key);
    if len(parts) <= 1 {
        return "";
    }
    out: str = parts[0];
    for i in range(1, len(parts) - 1) {
        out = out + "/" + parts[i];
    }
    return out;
}

def build_linear_chain(anchor: PathRoot, object_key: str) {
    parts: list[str] = split_object_key(object_key);
    prev_seg: Segment | None = None;
    built: str = "";
    for i in range(len(parts) - 1) {
        part = parts[i];
        depth = i + 1;
        if built == "" {
            fk = part;
        } else {
            fk = built + "/" + part;
        }
        seg = Segment(part=part, depth=depth, folder_key=fk, sid=fk);
        root ++> seg;
        if prev_seg is None {
            anchor +>:seg_next:+> seg;
        } else {
            prev_seg +>:seg_next:+> seg;
        }
        prev_seg = seg;
        built = fk;
    }
}

def collect_parent_folder_records(bucket_id: str, object_key: str) -> list[dict] {
    rows: list[dict] = [];
    if object_key == "" {
        return rows;
    }
    parts: list[str] = split_object_key(object_key);
    if len(parts) <= 1 {
        return rows;
    }
    anchor = PathRoot(bucket_id=bucket_id, object_key=object_key);
    root ++> anchor;
    build_linear_chain(anchor, object_key);
    claimed: dict[str, bool] = {};
    w = anchor spawn ParentRowCollector(claimed=claimed, bucket_id=bucket_id, rows=rows);
    out: list[dict] = [];
    for r in w.rows {
        out.append(r);
    }
    return out;
}

def insert_folder_batch(store: FolderStore, bucket_id: str, records: list[dict]) -> list[str] {
    created: list[str] = [];
    for rec in records {
        key = rec["key"];
        full_id = bucket_id + ":" + key;
        if full_id in store.existing {
            continue;
        }
        store.existing[full_id] = True;
        created.append(key);
    }
    return created;
}

def ensure_parent_folders(bucket_id: str, object_key: str, store: FolderStore) -> list[str] {
    records: list[dict] = collect_parent_folder_records(bucket_id, object_key);
    created: list[str] = insert_folder_batch(store, bucket_id, records);
    return created;
}

test "empty_key_no_records" {
    rows = collect_parent_folder_records("bkt", "");
    assert len(rows) == 0;
}

test "single_segment_no_parents" {
    rows = collect_parent_folder_records("bkt", "file.txt");
    assert len(rows) == 0;
}

test "multi_segment_parent_keys" {
    rows = collect_parent_folder_records("bkt", "a/b/c.txt");
    keys: list[str] = [];
    for r in rows {
        keys.append(r["key"] as str);
    }
    assert keys == ["a", "a/b"];
}

test "parent_row_depth_and_prefix" {
    rows = collect_parent_folder_records("bkt", "a/b/c.txt");
    assert (rows[0]["depth"] as int) == 1;
    assert (rows[0]["prefix"] as str) == "";
    assert (rows[1]["depth"] as int) == 2;
    assert (rows[1]["prefix"] as str) == "a";
}

test "ensure_parent_folders_creates_once" {
    store = FolderStore(existing={});
    created = ensure_parent_folders("bkt", "x/y/z.dat", store);
    keys: list[str] = [];
    for k in created {
        keys.append(k);
    }
    assert keys == ["x", "x/y"];
    again = ensure_parent_folders("bkt", "x/y/z.dat", store);
    assert len(again) == 0;
}

test "insert_batch_skips_existing" {
    store = FolderStore(existing={"bkt:a": True});
    recs: list[dict[str, str | int]] = [];
    r0: dict[str, str | int] = {};
    r0["bucket_id"] = "bkt";
    r0["key"] = "a";
    r0["prefix"] = "";
    r0["depth"] = 1;
    recs.append(r0);
    created = insert_folder_batch(store, "bkt", recs);
    assert len(created) == 0;
}
