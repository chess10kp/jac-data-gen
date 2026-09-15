"""Recursive directory watch scope — gorakhargosh/watchdog#386."""

node Dir {
    has path_id: str;
    has name: str;
}

edge Contains {}

walker RecursiveScan {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Dir entry {
        if here.path_id in self.claimed {
            skip;
        }
        self.claimed[here.path_id] = True;
        self.found.append(here.path_id);
        print("scan", here.path_id);
        kids: list[Dir] = [];
        for ch in [here ->:Contains:->][?:Dir] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        }
    }
}

def ensure_dir(path_id: str, name: str) -> Dir {
    nd = Dir(path_id=path_id, name=name);
    root ++> nd;
    return nd;
}

def build_home_tree() -> dict[str, Dir] {
    store: dict[str, Dir] = {};
    home = ensure_dir("home", "thomas");
    store["home"] = home;
    desktop = ensure_dir("home/desktop", "Desktop");
    store["home/desktop"] = desktop;
    documents = ensure_dir("home/documents", "Documents");
    store["home/documents"] = documents;
    notes = ensure_dir("home/desktop/notes", "notes");
    store["home/desktop/notes"] = notes;
    home +>:Contains:+> desktop;
    home +>:Contains:+> documents;
    desktop +>:Contains:+> notes;
    return store;
}

def build_diamond_tree() -> dict[str, Dir] {
    store: dict[str, Dir] = {};
    apex = ensure_dir("apex", "apex");
    store["apex"] = apex;
    left = ensure_dir("left", "left");
    store["left"] = left;
    right = ensure_dir("right", "right");
    store["right"] = right;
    join = ensure_dir("join", "join");
    store["join"] = join;
    apex +>:Contains:+> left;
    apex +>:Contains:+> right;
    left +>:Contains:+> join;
    right +>:Contains:+> join;
    return store;
}

def recursive_cte_descendants(root_id: str, store: dict[str, Dir]) -> list[str] {
    if root_id not in store {
        return [];
    }
    graph_root = store[root_id] as Dir;
    w = graph_root spawn RecursiveScan(claimed={});
    out: list[str] = [];
    for p in w.found {
        out.append(p);
    }
    out.sort();
    return out;
}

def expand_watch_scope(watch_id: str, recursive: bool, store: dict[str, Dir]) -> list[str] {
    if watch_id not in store {
        return [];
    }
    if recursive {
        return recursive_cte_descendants(watch_id, store);
    }
    return [watch_id];
}

def shallow_watch_gaps(watch_id: str, store: dict[str, Dir]) -> list[str] {
    if watch_id not in store {
        return [];
    }
    full = recursive_cte_descendants(watch_id, store);
    shallow = expand_watch_scope(watch_id, False, store);
    shallow_set: dict[str, bool] = {};
    for s in shallow {
        shallow_set[s] = True;
    }
    gaps: list[str] = [];
    for p in full {
        if p not in shallow_set {
            gaps.append(p);
        }
    }
    gaps.sort();
    return gaps;
}

test "covers_nested_desktop_notes" {
    store = build_home_tree();
    got = recursive_cte_descendants("home", store);
    assert (got == ["home", "home/desktop", "home/desktop/notes", "home/documents"]);;
}

test "parent nonrecursive exposes shallow coverage gaps" {
    store = build_home_tree();
    gaps = shallow_watch_gaps("home", store);
    assert (gaps == ["home/desktop", "home/desktop/notes", "home/documents"]);;
}

test "diamond revisit skips without truncating closure" {
    store = build_diamond_tree();
    got = recursive_cte_descendants("apex", store);
    assert (got == ["apex", "join", "left", "right"]);;
}

test "nonrecursive scope is root only" {
    store = build_home_tree();
    got = expand_watch_scope("home", False, store);
    assert (got == ["home"]);;
}

test "unknown watch id returns empty" {
    store = build_home_tree();
    assert (recursive_cte_descendants("missing", store) == []);;
    assert (expand_watch_scope("missing", True, store) == []);;
    assert (shallow_watch_gaps("missing", store) == []);;
}
