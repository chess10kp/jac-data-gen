"""sgaunet/s3xplorer#79 — ensureParentFolders N+1 vs batch parent creation."""

import from collections { defaultdict }

node PathSeg {
    has name: str;
    has depth: int = 0;
    has prefix: str = "";
    has cid: str;
    has is_last: bool = False;
}

edge SegNext {}
edge SegFork {}

obj FolderStore {
    has folders: dict[str, bool] = {};
    has query_count: int = 0;
    has bucket_id: str = "";
}

def split_path_parts(path: str) -> list[str] {
    parts: list[str] = [];
    raw: list[str] = path.split("/");
    for p in raw {
        if p {
            parts.append(p);
        }
    }
    return parts;
}

def parent_folder_keys(object_key: str) -> list[str] {
    parts = split_path_parts(object_key);
    keys: list[str] = [];
    if len(parts) < 2 {
        return keys;
    }
    prefix: str = "";
    for i in range(len(parts) - 1) {
        if prefix {
            prefix = prefix + "/" + parts[i];
        } else {
            prefix = parts[i];
        }
        keys.append(prefix + "/");
    }
    return keys;
}

def _fid(bucket_id: str, key: str) -> str {
    return bucket_id + "|" + key;
}

def folder_exists(store: FolderStore, bucket_id: str, key: str) -> bool {
    fid = _fid(bucket_id, key);
    if fid in store.folders {
        return store.folders[fid];
    }
    return False;
}

def _insert_one(store: FolderStore, bucket_id: str, key: str) -> bool {
    store.query_count = store.query_count + 1;
    fid = _fid(bucket_id, key);
    if fid in store.folders and store.folders[fid] {
        return False;
    }
    store.folders[fid] = True;
    return True;
}

def _insert_batch(store: FolderStore, bucket_id: str, keys: list[str]) -> list[str] {
    store.query_count = store.query_count + 1;
    created: list[str] = [];
    for k in keys {
        fid = _fid(bucket_id, k);
        if fid in store.folders and store.folders[fid] {
            continue;
        }
        store.folders[fid] = True;
        created.append(k);
    }
    return created;
}

def build_path_graph(parts: list[str]) -> PathSeg {
    head: PathSeg | None = None;
    prev: PathSeg | None = None;
    prefix: str = "";
    last_idx = len(parts) - 1;
    for i in range(len(parts)) {
        if i > 0 {
            prefix = prefix + "/" + parts[i];
        } else {
            prefix = parts[i];
        }
        is_last = False;
        if i == last_idx {
            is_last = True;
        }
        seg = PathSeg(
            name=parts[i],
            depth=i,
            prefix=prefix,
            cid="seg-" + str(i),
            is_last=is_last
        );
        root ++> seg;
        if prev {
            prev +>:SegNext:+> seg;
        } else {
            head = seg;
        }
        prev = seg;
    }
    if head {
        return head;
    }
    seg = PathSeg(name="", depth=0, prefix="", cid="seg-empty", is_last=True);
    root ++> seg;
    return seg;
}

def build_diamond_graph -> PathSeg {
    a = PathSeg(name="a", depth=0, prefix="a", cid="dia-a", is_last=False);
    b = PathSeg(name="b", depth=1, prefix="a/b", cid="dia-b", is_last=False);
    c = PathSeg(name="c", depth=1, prefix="a/c", cid="dia-c", is_last=False);
    d = PathSeg(name="d", depth=2, prefix="a/b/d", cid="dia-d", is_last=False);
    root ++> a;
    root ++> b;
    root ++> c;
    root ++> d;
    a +>:SegNext:+> b;
    a +>:SegFork:+> c;
    b +>:SegNext:+> d;
    c +>:SegNext:+> d;
    return a;
}

walker CollectParents {
    has parents: list[str] = [];
    has claimed: dict[str, bool] = {};
    has visit_count: int = 0;
    can walk_seg with PathSeg entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.visit_count = self.visit_count + 1;
        if not here.is_last {
            self.parents.append(here.prefix + "/");
        }
        kids: list[PathSeg] = [];
        nxt: list[PathSeg] = [here ->:SegNext:->][?:PathSeg];
        frk: list[PathSeg] = [here ->:SegFork:->][?:PathSeg];
        for kn in nxt {
            kids.append(kn);
        }
        for kf in frk {
            kids.append(kf);
        }
        for ch in kids {
            visit :0: ch;
        }
        print self.visit_count;
    }
}

def collect_parents_walk(head: PathSeg) -> list[str] {
    w = head spawn CollectParents(claimed={});
    return w.parents;
}

def ensure_parent_folders(
    store: FolderStore,
    bucket_id: str,
    object_key: str,
    batch: bool = False
) -> list[str] {
    parts = split_path_parts(object_key);
    if not batch {
        keys = parent_folder_keys(object_key);
        created: list[str] = [];
        for pk in keys {
            if _insert_one(store, bucket_id, pk) {
                created.append(pk);
            }
        }
        return created;
    }
    if not parts {
        return [];
    }
    head = build_path_graph(parts);
    w = head spawn CollectParents(claimed={});
    missing: list[str] = [];
    for pk in w.parents {
        if not folder_exists(store, bucket_id, pk) {
            missing.append(pk);
        }
    }
    return _insert_batch(store, bucket_id, missing);
}

def insert_query_count(store: FolderStore) -> int {
    return store.query_count;
}
