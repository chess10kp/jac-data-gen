"""sgaunet/s3xplorer#79 - Fix N+1 query pattern in ensureParentFolders."""

node Part {
    has name: str;
    has depth: int;
    has cid: str;
}

node BucketStore {
    has bid: str;
    has folder_keys: dict[str, bool] = {};
    has query_count: int = 0;
}

edge Step {}

walker CollectFolders {
    has claimed: dict[str, bool] = {};
    has keys: list[str] = [];
    has prefix: str = "";

    can walk with Part entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.prefix = self.prefix + here.name + "/";
        self.keys.append(self.prefix);
        kids: list[Part] = [here ->:Step:->][?:Part];
        i: int = 0;
        while i < len(kids) {
            j: int = i + 1;
            while j < len(kids) {
                if kids[j].cid < kids[i].cid {
                    tmp = kids[i];
                    kids[i] = kids[j];
                    kids[j] = tmp;
                }
                j = j + 1;
            }
            i = i + 1;
        }
        if len(kids) > 0 {
            for ch in kids {
                visit [ch];
            }
        } else {
            disengage;
        }
    }
}

def split_key_parts(object_key: str) -> list[str] {
    raw: list[str] = object_key.split("/");
    parts: list[str] = [];
    for seg in raw {
        if seg != "" {
            parts.append(seg);
        }
    }
    if len(parts) == 0 {
        return [];
    }
    if not object_key.endswith("/") {
        trimmed: list[str] = [];
        i: int = 0;
        last: int = len(parts) - 1;
        while i < last {
            trimmed.append(parts[i]);
            i = i + 1;
        }
        parts = trimmed;
    }
    return parts;
}

def parent_folder_keys(parts: list[str]) -> list[str] {
    keys: list[str] = [];
    prefix: str = "";
    for part in parts {
        prefix = prefix + part + "/";
        keys.append(prefix);
    }
    return keys;
}

def build_part_chain(parts: list[str]) -> Part | None {
    if len(parts) == 0 {
        return None;
    }
    head: Part | None = None;
    prev: Part | None = None;
    depth: int = 0;
    for part in parts {
        depth = depth + 1;
        cid: str = str(depth) + ":" + part;
        nd = Part(name=part, depth=depth, cid=cid);
        if head is None {
            head = nd;
        }
        if prev is not None {
            prev +>:Step:+> nd;
        }
        prev = nd;
    }
    return head;
}

def build_diamond_parts() -> Part {
    a = Part(name="a", depth=1, cid="a");
    b = Part(name="b", depth=2, cid="b");
    c = Part(name="c", depth=2, cid="c_alt");
    d = Part(name="d", depth=3, cid="d");
    a +>:Step:+> b;
    a +>:Step:+> c;
    b +>:Step:+> d;
    c +>:Step:+> d;
    return a;
}

def collect_folder_keys(graph_root: Part) -> list[str] {
    w = graph_root spawn CollectFolders(claimed={}, keys=[], prefix="");
    print("collect_folder_keys=" + str(w.keys));
    return w.keys;
}

def ensure_parent_folders(store: BucketStore, bucket_id: str, object_key: str) -> list[str] {
    if store.bid != bucket_id {
        return [];
    }
    parts = split_key_parts(object_key);
    if len(parts) == 0 {
        return [];
    }
    graph_root = build_part_chain(parts);
    if graph_root is None {
        return [];
    }
    w = graph_root spawn CollectFolders(claimed={}, keys=[], prefix="");
    print("ensure_parent_folders batch keys=" + str(w.keys));
    created: list[str] = [];
    store.query_count = store.query_count + 1;
    for key in w.keys {
        if key not in store.folder_keys {
            store.folder_keys[key] = True;
            created.append(key);
        }
    }
    return sorted(created);
}

def ensure_parent_folders_n_plus_one(store: BucketStore, bucket_id: str, object_key: str) -> list[str] {
    if store.bid != bucket_id {
        return [];
    }
    parts = split_key_parts(object_key);
    keys = parent_folder_keys(parts);
    created: list[str] = [];
    for key in keys {
        store.query_count = store.query_count + 1;
        if key not in store.folder_keys {
            store.folder_keys[key] = True;
            created.append(key);
        }
    }
    return sorted(created);
}

"""sgaunet/s3xplorer#79 - Fix N+1 query pattern in ensureParentFolders."""

node Part {
    has name: str;
    has depth: int;
    has cid: str;
}

node BucketStore {
    has bid: str;
    has folder_keys: dict[str, bool] = {};
    has query_count: int = 0;
}

edge Step {}

walker CollectFolders {
    has claimed: dict[str, bool] = {};
    has keys: list[str] = [];
    has prefix: str = "";

    can walk with Part entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.prefix = self.prefix + here.name + "/";
        self.keys.append(self.prefix);
        kids: list[Part] = [here ->:Step:->][?:Part];
        i: int = 0;
        while i < len(kids) {
            j: int = i + 1;
            while j < len(kids) {
                if kids[j].cid < kids[i].cid {
                    tmp = kids[i];
                    kids[i] = kids[j];
                    kids[j] = tmp;
                }
                j = j + 1;
            }
            i = i + 1;
        }
        if len(kids) > 0 {
            for ch in kids {
                visit [ch];
            }
        } else {
            disengage;
        }
    }
}

def split_key_parts(object_key: str) -> list[str] {
    raw: list[str] = object_key.split("/");
    parts: list[str] = [];
    for seg in raw {
        if seg != "" {
            parts.append(seg);
        }
    }
    if len(parts) == 0 {
        return [];
    }
    if not object_key.endswith("/") {
        trimmed: list[str] = [];
        i: int = 0;
        last: int = len(parts) - 1;
        while i < last {
            trimmed.append(parts[i]);
            i = i + 1;
        }
        parts = trimmed;
    }
    return parts;
}

def parent_folder_keys(parts: list[str]) -> list[str] {
    keys: list[str] = [];
    prefix: str = "";
    for part in parts {
        prefix = prefix + part + "/";
        keys.append(prefix);
    }
    return keys;
}

def build_part_chain(parts: list[str]) -> Part | None {
    if len(parts) == 0 {
        return None;
    }
    head: Part | None = None;
    prev: Part | None = None;
    depth: int = 0;
    for part in parts {
        depth = depth + 1;
        cid: str = str(depth) + ":" + part;
        nd = Part(name=part, depth=depth, cid=cid);
        if head is None {
            head = nd;
        }
        if prev is not None {
            prev +>:Step:+> nd;
        }
        prev = nd;
    }
    return head;
}

def build_diamond_parts() -> Part {
    a = Part(name="a", depth=1, cid="a");
    b = Part(name="b", depth=2, cid="b");
    c = Part(name="c", depth=2, cid="c_alt");
    d = Part(name="d", depth=3, cid="d");
    a +>:Step:+> b;
    a +>:Step:+> c;
    b +>:Step:+> d;
    c +>:Step:+> d;
    return a;
}

def collect_folder_keys(graph_root: Part) -> list[str] {
    w = graph_root spawn CollectFolders(claimed={}, keys=[], prefix="");
    print("collect_folder_keys=" + str(w.keys));
    return w.keys;
}

def ensure_parent_folders(store: BucketStore, bucket_id: str, object_key: str) -> list[str] {
    if store.bid != bucket_id {
        return [];
    }
    parts = split_key_parts(object_key);
    if len(parts) == 0 {
        return [];
    }
    graph_root = build_part_chain(parts);
    if graph_root is None {
        return [];
    }
    w = graph_root spawn CollectFolders(claimed={}, keys=[], prefix="");
    print("ensure_parent_folders batch keys=" + str(w.keys));
    created: list[str] = [];
    store.query_count = store.query_count + 1;
    for key in w.keys {
        if key not in store.folder_keys {
            store.folder_keys[key] = True;
            created.append(key);
        }
    }
    return sorted(created);
}

def ensure_parent_folders_n_plus_one(store: BucketStore, bucket_id: str, object_key: str) -> list[str] {
    if store.bid != bucket_id {
        return [];
    }
    parts = split_key_parts(object_key);
    keys = parent_folder_keys(parts);
    created: list[str] = [];
    for key in keys {
        store.query_count = store.query_count + 1;
        if key not in store.folder_keys {
            store.folder_keys[key] = True;
            created.append(key);
        }
    }
    return sorted(created);
}

test "split_key_file_object" {
    parts = split_key_parts("a/b/c.txt");
    assert len(parts) == 2;
    assert parts[0] == "a";
    assert parts[1] == "b";
}

test "ensure_batch_single_query" {
    store = BucketStore(bid="b1", folder_keys={}, query_count=0);
    created = ensure_parent_folders(store, "b1", "a/b/c.txt");
    assert store.query_count == 1;
    assert sorted(created) == ["a/", "a/b/"];
}

test "ensure_n_plus_one_queries" {
    store = BucketStore(bid="b1", folder_keys={}, query_count=0);
    created = ensure_parent_folders_n_plus_one(store, "b1", "a/b/c.txt");
    assert store.query_count == 2;
    assert sorted(created) == ["a/", "a/b/"];
}

test "wrong_bucket_empty" {
    store = BucketStore(bid="b1", folder_keys={}, query_count=0);
    created = ensure_parent_folders(store, "b2", "a/b/");
    assert len(created) == 0;
}

test "linear_chain_collect" {
    graph_root = build_part_chain(["x", "y", "z"]);
    keys = collect_folder_keys(graph_root);
    assert sorted(keys) == ["x/", "x/y/", "x/y/z/"];
}

test "diamond_revisit_skips_second_d" {
    graph_root = build_diamond_parts();
    keys = collect_folder_keys(graph_root);
    assert sorted(keys) == ["a/", "a/b/", "a/b/d/", "a/c/"];
    has_c_d: bool = False;
    for k in keys {
        if k == "a/c/d/" {
            has_c_d = True;
        }
    }
    assert has_c_d == False;
}
