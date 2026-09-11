"""Guard: sibiryoff/ottertwin#9."""

node FsEntry { has path: str; has is_dir: bool = False; }
edge Contains {}
obj FsStore { has entries: dict[str, FsEntry] = {}; }

walker CopyPlan {
    has claimed: dict[str, bool] = {};
    has plan: list[str] = [];
    can step with FsEntry entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        self.plan.append(here.path);
        if here.is_dir {
            for ch in [here ->:Contains:->][?:FsEntry] {
                if ch.path in self.claimed { continue; }
                if ch.is_dir {
                    sub = ch spawn CopyPlan(claimed=self.claimed, plan=self.plan);
                    self.claimed = sub.claimed;
                    self.plan = sub.plan;
                } else {
                    self.claimed[ch.path] = True;
                    self.plan.append(ch.path);
                }
            }
        }
    }
}

def load_fs_tree(
    entries: list[str],
    is_dir: dict[str, bool],
    parent_edges: list[tuple[str, str | None]],
) -> FsStore {
    store = FsStore();
    for path in entries {
        nd = FsEntry(path=path, is_dir=is_dir.get(path, False));
        root ++> nd;
        store.entries[path] = nd;
    }
    for (path, par) in parent_edges {
        if par is None { continue; }
        p = store.entries.get(par, None);
        c = store.entries.get(path, None);
        if p is not None and c is not None { p +>:Contains:+> c; }
    }
    return store;
}

def plan_copy(store: FsStore, root_path: str) -> list[str] {
    nd = store.entries.get(root_path, None);
    if nd is None { return []; }
    if not nd.is_dir { return [root_path]; }
    w = nd spawn CopyPlan(claimed={}, plan=[]);
    return w.plan;
}

def collect_files(store: FsStore, dir_path: str) -> list[str] {
    items = plan_copy(store, dir_path);
    out: list[str] = [];
    for p in items {
        e = store.entries.get(p, None);
        if e is not None and not e.is_dir { out.append(p); }
    }
    return out;
}

test "recursive copy plan" {
    store = load_fs_tree(
        ["/src", "/src/a", "/src/a/file.txt", "/src/b"],
        {"/src": True, "/src/a": True, "/src/a/file.txt": False, "/src/b": False},
        [("/src", None), ("/src/a", "/src"), ("/src/a/file.txt", "/src/a"), ("/src/b", "/src")],
    );
    assert plan_copy(store, "/src") == ["/src", "/src/a", "/src/a/file.txt", "/src/b"];
    assert collect_files(store, "/src") == ["/src/a/file.txt", "/src/b"];
}
