"""guardian/giant#744 — Workspace lazy-loading tree with expand-on-demand tracking."""

node Folder {
    has name: str;
    has expandable: bool = False;
    has loaded: bool = False;
}

edge ChildOf {}

obj WorkspaceTree {
    has folders: dict[str, Folder] = {};
}

def load_workspace(folders: list[tuple[str, str | None, bool]]) -> WorkspaceTree {
    tree = WorkspaceTree();
    for (name, parent, has_children) in folders {
        if parent is not None and tree.folders.get(parent, None) is None {
            raise KeyError("unknown parent folder");
        }
        nd = Folder(name=name, expandable=has_children);
        root ++> nd;
        tree.folders[name] = nd;
        if parent is not None {
            p = tree.folders.get(parent, None);
            if p is not None { p +>:ChildOf:+> nd; }
        }
    }
    return tree;
}

def mark_loaded(tree: WorkspaceTree, folder_ids: list[str]) -> list[str] {
    newly: list[str] = [];
    for fid in folder_ids {
        nd = tree.folders.get(fid, None);
        if nd is not None and not nd.loaded {
            nd.loaded = True;
            newly.append(fid);
        }
    }
    return sorted(newly);
}

def expandable_folders(tree: WorkspaceTree) -> list[str] {
    out: list[str] = [];
    for name in sorted(tree.folders.keys()) {
        nd = tree.folders.get(name, None);
        if nd is not None and nd.expandable and not nd.loaded { out.append(name); }
    }
    return out;
}

def loaded_children(tree: WorkspaceTree, folder: str) -> list[str] {
    nd = tree.folders.get(folder, None);
    if nd is None or not nd.loaded { return []; }
    out: list[str] = [];
    for ch in [nd ->:ChildOf:->][?:Folder] {
        if ch.loaded { out.append(ch.name); }
    }
    return sorted(out);
}

def ancestor_path(tree: WorkspaceTree, folder: str) -> list[str] {
    nd = tree.folders.get(folder, None);
    if nd is None { return []; }
    chain: list[str] = [];
    cur: Folder | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.name in seen { break; }
        seen[cur.name] = True;
        chain.append(cur.name);
        parent: Folder | None = None;
        for p in [cur <-:ChildOf:<-][?:Folder] {
            parent = p;
            break;
        }
        cur = parent;
    }
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

test "lazy expand tracking" {
    t = load_workspace([
        ("ws", None, True),
        ("docs", "ws", True),
        ("images", "ws", True),
        ("2024", "docs", False),
    ]);
    assert expandable_folders(t) == ["docs", "images", "ws"];
    assert mark_loaded(t, ["ws"]) == ["ws"];
    assert loaded_children(t, "ws") == [];
    assert expandable_folders(t) == ["docs", "images"];
    assert ancestor_path(t, "2024") == ["ws", "docs", "2024"];
}

test "load children on expand" {
    t2 = load_workspace([("root", None, True), ("a", "root", False), ("b", "root", False)]);
    mark_loaded(t2, ["root", "a"]);
    assert loaded_children(t2, "root") == ["a"];
}
