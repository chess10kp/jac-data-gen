"""larabail/UrDatabase#18 — Recursive library scan can follow symlink cycles."""

node LibraryDir {
    has path: str;
    has is_reparse: bool = False;
}

edge Subdir {}

obj ScanStore {
    has dirs: dict[str, LibraryDir] = {};
}

walker SubdirWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has follow_links: bool = False;
    has start_path: str = "";

    can step with LibraryDir entry {
        if here.path in self.claimed { skip; }
        if not self.follow_links and here.is_reparse and here.path != self.start_path { skip; }
        self.claimed[here.path] = True;
        self.found.append(here.path);
        visit [->:Subdir:->][?:LibraryDir];
    }
}

def load_library(
    dir_names: list[str],
    child_edges: list[tuple[str, str]],
    reparse_points: list[str] | None = None,
) -> ScanStore {
    store = ScanStore();
    for name in dir_names {
        nd = LibraryDir(path=name, is_reparse=False);
        if reparse_points is not None and name in reparse_points {
            nd.is_reparse = True;
        }
        root ++> nd;
        store.dirs[name] = nd;
    }
    for (parent, child) in child_edges {
        p = store.dirs.get(parent, None);
        c = store.dirs.get(child, None);
        if p is not None and c is not None { p +>:Subdir:+> c; }
    }
    return store;
}

def scan_subdirs(store: ScanStore, `root: str, follow_links: bool = False) -> list[str] {
    nd = store.dirs.get(`root, None);
    if nd is None { return []; }
    w = nd spawn SubdirWalk(claimed={}, follow_links=follow_links, start_path=`root);
    return sorted(w.found);
}

def reachable_without_guard(store: ScanStore, `root: str) -> list[str] {
    nd = store.dirs.get(`root, None);
    if nd is None { return []; }
    w = nd spawn SubdirWalk(claimed={}, follow_links=True, start_path=`root);
    return sorted(w.found);
}

test "scan skips reparse unless follow_links" {
    g = load_library(
        ["lib", "a", "b", "c", "link"],
        [("lib", "a"), ("a", "b"), ("b", "c"), ("c", "link"), ("link", "a")],
        reparse_points=["link"],
    );
    assert scan_subdirs(g, "lib") == ["a", "b", "c", "lib"];
    assert scan_subdirs(g, "lib", follow_links=True) == ["a", "b", "c", "lib", "link"];
}
