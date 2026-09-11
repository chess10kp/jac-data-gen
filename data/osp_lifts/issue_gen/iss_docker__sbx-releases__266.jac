"""docker/sbx-releases#266 — Virtiofs directory tree walk for mutation hotspots."""

node DirEntry {
    has path: str;
    has kind: str;
}

edge Contains {}

obj DirStore {
    has entries: dict[str, DirEntry] = {};
}

walker SubtreeWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with DirEntry entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        self.found.append(here.path);
        visit [->:Contains:->][?:DirEntry];
    }
}

walker DepthWalk {
    has claimed: dict[str, bool] = {};
    has best: int = 0;
    has depth: int = 0;

    can step with DirEntry entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if self.depth > self.best { self.best = self.depth; }
        self.depth += 1;
        visit [->:Contains:->][?:DirEntry];
        self.depth -= 1;
    }
}

def load_tree(
    entries: list[tuple[str, str]],
    contains: list[tuple[str, str]],
) -> DirStore {
    store = DirStore();
    for (path, kind) in entries {
        if path not in store.entries {
            nd = DirEntry(path=path, kind=kind);
            root ++> nd;
            store.entries[path] = nd;
        }
    }
    for (parent, child) in contains {
        p = store.entries.get(parent, None);
        c = store.entries.get(child, None);
        if p is not None and c is not None { p +>:Contains:+> c; }
    }
    return store;
}

def subtree_file_count(store: DirStore, root_path: str) -> int {
    nd = store.entries.get(root_path, None);
    if nd is None { return 0; }
    found: list[str] = [];
    claimed: dict[str, bool] = {};
    claimed[root_path] = True;
    for ch in [nd ->:Contains:->][?:DirEntry] {
        w = ch spawn SubtreeWalk(claimed=claimed, found=found);
        found = w.found;
        claimed = w.claimed;
    }
    count = 0;
    for p in found {
        e = store.entries.get(p, None);
        if e is not None and e.kind == "file" { count += 1; }
    }
    return count;
}

def subtree_paths(store: DirStore, root_path: str) -> list[str] {
    nd = store.entries.get(root_path, None);
    if nd is None { return []; }
    found: list[str] = [];
    claimed: dict[str, bool] = {};
    claimed[root_path] = True;
    for ch in [nd ->:Contains:->][?:DirEntry] {
        w = ch spawn SubtreeWalk(claimed=claimed, found=found);
        found = w.found;
        claimed = w.claimed;
    }
    return sorted(found);
}

def max_depth(store: DirStore, root_path: str) -> int {
    nd = store.entries.get(root_path, None);
    if nd is None { return 0; }
    best = 0;
    pending: list[tuple[str, int]] = [(root_path, 0)];
    seen: dict[str, bool] = {root_path: True};
    while len(pending) > 0 {
        (cur, depth) = pending.pop();
        if depth > best { best = depth; }
        entry = store.entries.get(cur, None);
        if entry is None { continue; }
        for ch in [entry ->:Contains:->][?:DirEntry] {
            if ch.path not in seen {
                seen[ch.path] = True;
                pending.append((ch.path, depth + 1));
            }
        }
    }
    return best;
}

def entry_kind(store: DirStore, path: str) -> str | None {
    nd = store.entries.get(path, None);
    if nd is None { return None; }
    return nd.kind;
}
