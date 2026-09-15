"""Recursive directory path building — anchor plus recursive expansion (jOOQ/jOOQ#12961)."""

node Directory {
    has id: str;
    has label: str;
    has parent_id: str = "";
    has path: str = "";
}

edge ParentOf {}

def build_directory_graph(rows: list[list[str]]) -> object {
    nodes: dict[str, Directory] = {};
    root_ids: list[str] = [];
    for row in rows {
        nid: str = row[0];
        nlabel: str = row[1];
        pid: str = row[2];
        nd = Directory(id=nid, label=nlabel, parent_id=pid);
        nodes[nid] = nd;
        root ++> nd;
    }
    for row in rows {
        nid: str = row[0];
        pid: str = row[2];
        if pid != "" {
            pnd = nodes[pid];
            cnd = nodes[nid];
            pnd +>:ParentOf:+> cnd;
        } else {
            root_ids.append(nid);
        }
    }
    handle: dict = {};
    handle["nodes"] = nodes;
    handle["root_ids"] = root_ids;
    return handle;
}

walker AnchorGuard {
    has claimed: dict[str, bool] = {};
    has paths: dict[str, str] = {};

    can anchor with Directory entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        if here.parent_id == "" {
            self.paths[here.id] = here.label;
            here.path = here.label;
            print("anchor", here.id, here.path);
        }
        kids: list[Directory] = [here ->:ParentOf:->][?:Directory];
        for kid in kids {
            visit [kid];
        }
    }
}

walker RecursiveExpand {
    has claimed: dict[str, bool] = {};
    has paths: dict[str, str] = {};
    has added: int = 0;

    can expand with Directory entry {
        if here.parent_id != "" and here.parent_id not in self.paths {
            skip;
        }
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        if here.id not in self.paths {
            if here.parent_id == "" {
                self.paths[here.id] = here.label;
                self.added = self.added + 1;
            } elif here.parent_id in self.paths {
                pp: str = self.paths[here.parent_id];
                self.paths[here.id] = pp + "\\" + here.label;
                self.added = self.added + 1;
            }
        }
        if here.id in self.paths {
            here.path = self.paths[here.id];
            print("recursive", here.id, here.path);
            kids: list[Directory] = [here ->:ParentOf:->][?:Directory];
            for kid in kids {
                visit [kid];
            }
        }
    }
}

def recursive_paths(handle: object) -> dict[str, str] {
    store = handle as dict;
    nodes = store["nodes"] as dict[str, Directory];
    root_ids = store["root_ids"] as list[str];
    paths: dict[str, str] = {};
    anchor_claimed: dict[str, bool] = {};
    for rid in root_ids {
        nd = nodes[rid];
        w: AnchorGuard = nd spawn AnchorGuard(claimed=anchor_claimed, paths=paths);
        anchor_claimed = w.claimed;
        for pk in w.paths {
            paths[pk] = w.paths[pk];
        }
    }
    max_passes: int = len(nodes);
    pass_i: int = 0;
    while pass_i < max_passes {
        pass_i = pass_i + 1;
        wave_claimed: dict[str, bool] = {};
        wave_added: int = 0;
        for rid in root_ids {
            nd = nodes[rid];
            w: RecursiveExpand = nd spawn RecursiveExpand(claimed=wave_claimed, paths=paths, added=0);
            wave_claimed = w.claimed;
            delta: int = w.added;
            wave_added = wave_added + delta;
            for pk in w.paths {
                paths[pk] = w.paths[pk];
            }
        }
        if wave_added == 0 {
            break;
        }
    }
    return paths;
}

def recursive_path_rows(handle: object) -> list[list[str]] {
    paths = recursive_paths(handle);
    store = handle as dict;
    nodes = store["nodes"] as dict[str, Directory];
    ids: list[str] = [];
    for nk in nodes {
        ids.append(nk);
    }
    sorted_ids = sorted(ids);
    rows: list[list[str]] = [];
    for sid in sorted_ids {
        nd = nodes[sid];
        p: str = "";
        if sid in paths {
            p = paths[sid];
        }
        row: list[str] = [nd.id, nd.label, p];
        rows.append(row);
    }
    return rows;
}

def lookup_path(handle: object, node_id: str) -> str {
    paths = recursive_paths(handle);
    if node_id in paths {
        return paths[node_id];
    }
    return "";
}

"""Recursive directory path building — anchor plus recursive expansion (jOOQ/jOOQ#12961)."""

node Directory {
    has id: str;
    has label: str;
    has parent_id: str = "";
    has path: str = "";
}

edge ParentOf {}

def build_directory_graph(rows: list[list[str]]) -> object {
    nodes: dict[str, Directory] = {};
    root_ids: list[str] = [];
    for row in rows {
        nid: str = row[0];
        nlabel: str = row[1];
        pid: str = row[2];
        nd = Directory(id=nid, label=nlabel, parent_id=pid);
        nodes[nid] = nd;
        root ++> nd;
    }
    for row in rows {
        nid: str = row[0];
        pid: str = row[2];
        if pid != "" {
            pnd = nodes[pid];
            cnd = nodes[nid];
            pnd +>:ParentOf:+> cnd;
        } else {
            root_ids.append(nid);
        }
    }
    handle: dict = {};
    handle["nodes"] = nodes;
    handle["root_ids"] = root_ids;
    return handle;
}

walker AnchorGuard {
    has claimed: dict[str, bool] = {};
    has paths: dict[str, str] = {};

    can anchor with Directory entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        if here.parent_id == "" {
            self.paths[here.id] = here.label;
            here.path = here.label;
            print("anchor", here.id, here.path);
        }
        kids: list[Directory] = [here ->:ParentOf:->][?:Directory];
        for kid in kids {
            visit [kid];
        }
    }
}

walker RecursiveExpand {
    has claimed: dict[str, bool] = {};
    has paths: dict[str, str] = {};
    has added: int = 0;

    can expand with Directory entry {
        if here.parent_id != "" and here.parent_id not in self.paths {
            skip;
        }
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        if here.id not in self.paths {
            if here.parent_id == "" {
                self.paths[here.id] = here.label;
                self.added = self.added + 1;
            } elif here.parent_id in self.paths {
                pp: str = self.paths[here.parent_id];
                self.paths[here.id] = pp + "\\" + here.label;
                self.added = self.added + 1;
            }
        }
        if here.id in self.paths {
            here.path = self.paths[here.id];
            print("recursive", here.id, here.path);
            kids: list[Directory] = [here ->:ParentOf:->][?:Directory];
            for kid in kids {
                visit [kid];
            }
        }
    }
}

def recursive_paths(handle: object) -> dict[str, str] {
    store = handle as dict;
    nodes = store["nodes"] as dict[str, Directory];
    root_ids = store["root_ids"] as list[str];
    paths: dict[str, str] = {};
    anchor_claimed: dict[str, bool] = {};
    for rid in root_ids {
        nd = nodes[rid];
        w: AnchorGuard = nd spawn AnchorGuard(claimed=anchor_claimed, paths=paths);
        anchor_claimed = w.claimed;
        for pk in w.paths {
            paths[pk] = w.paths[pk];
        }
    }
    max_passes: int = len(nodes);
    pass_i: int = 0;
    while pass_i < max_passes {
        pass_i = pass_i + 1;
        wave_claimed: dict[str, bool] = {};
        wave_added: int = 0;
        for rid in root_ids {
            nd = nodes[rid];
            w: RecursiveExpand = nd spawn RecursiveExpand(claimed=wave_claimed, paths=paths, added=0);
            wave_claimed = w.claimed;
            delta: int = w.added;
            wave_added = wave_added + delta;
            for pk in w.paths {
                paths[pk] = w.paths[pk];
            }
        }
        if wave_added == 0 {
            break;
        }
    }
    return paths;
}

def recursive_path_rows(handle: object) -> list[list[str]] {
    paths = recursive_paths(handle);
    store = handle as dict;
    nodes = store["nodes"] as dict[str, Directory];
    ids: list[str] = [];
    for nk in nodes {
        ids.append(nk);
    }
    sorted_ids = sorted(ids);
    rows: list[list[str]] = [];
    for sid in sorted_ids {
        nd = nodes[sid];
        p: str = "";
        if sid in paths {
            p = paths[sid];
        }
        row: list[str] = [nd.id, nd.label, p];
        rows.append(row);
    }
    return rows;
}

def lookup_path(handle: object, node_id: str) -> str {
    paths = recursive_paths(handle);
    if node_id in paths {
        return paths[node_id];
    }
    return "";
}

test "linear_chain_paths" {
    rows: list[list[str]] = [
        ["r", "Root", ""],
        ["a", "Alpha", "r"],
        ["b", "Beta", "a"],
    ];
    h = build_directory_graph(rows);
    p = recursive_paths(h);
    assert (p["r"] == "Root");
    assert (p["a"] == "Root\\Alpha");
    assert (p["b"] == "Root\\Alpha\\Beta");
}

test "lookup_known_and_missing" {
    rows: list[list[str]] = [
        ["r", "Root", ""],
        ["x", "Leaf", "r"],
    ];
    h = build_directory_graph(rows);
    assert (lookup_path(h, "x") == "Root\\Leaf");
    assert (lookup_path(h, "missing") == "");
}

test "recursive_path_rows_sorted" {
    rows: list[list[str]] = [
        ["z", "Zed", ""],
        ["a", "Ace", "z"],
    ];
    h = build_directory_graph(rows);
    got = recursive_path_rows(h);
    want: list[list[str]] = [
        ["a", "Ace", "Zed\\Ace"],
        ["z", "Zed", "Zed"],
    ];
    assert (got == want);
}

test "multi_root_forest" {
    rows: list[list[str]] = [
        ["r1", "One", ""],
        ["r2", "Two", ""],
        ["c1", "Child", "r1"],
    ];
    h = build_directory_graph(rows);
    p = recursive_paths(h);
    assert (p["r1"] == "One");
    assert (p["r2"] == "Two");
    assert (p["c1"] == "One\\Child");
    assert (("c2" in p) == False);
}

test "orphan_without_anchor_stays_empty" {
    rows: list[list[str]] = [
        ["r", "Root", ""],
        ["o", "Orphan", "ghost"],
    ];
    h = build_directory_graph(rows);
    p = recursive_paths(h);
    assert (p["r"] == "Root");
    assert (("o" in p) == False);
    assert (lookup_path(h, "o") == "");
}
