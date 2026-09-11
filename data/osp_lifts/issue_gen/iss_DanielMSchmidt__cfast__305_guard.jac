"""DanielMSchmidt/cfast#305 — folder visibility inheritance parent walk."""

node Folder {
    has fid: str;
    has visibility: str;
}

edge ChildOf {}

obj FolderTree {
    has folders: dict[str, Folder] = {};
}

def load_folders(parents: dict[str, str | None], visibility: dict[str, str]) -> FolderTree {
    reg = FolderTree();
    for fid in parents.keys() {
        vis = visibility.get(fid, "inherit");
        nd = Folder(fid=fid, visibility=vis);
        root ++> nd;
        reg.folders[fid] = nd;
    }
    for fid in parents.keys() {
        p = parents[fid];
        if p is not None {
            pa = reg.folders.get(p, None);
            ch = reg.folders.get(fid, None);
            if pa is not None and ch is not None { ch +>:ChildOf:+> pa; }
        }
    }
    return reg;
}

def _walk_up(reg: FolderTree, fid: str) -> list[str] {
    nd = reg.folders.get(fid, None);
    if nd is None { return []; }
    chain: list[str] = [];
    cur: Folder | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.fid in seen { break; }
        seen[cur.fid] = True;
        chain.append(cur.fid);
        parent: Folder | None = None;
        for p in [cur ->:ChildOf:->][?:Folder] {
            parent = p;
            break;
        }
        cur = parent;
    }
    return chain;
}

def effective_visibility(reg: FolderTree, folder: str) -> str {
    if folder not in reg.folders { return "restricted"; }
    for fid in _walk_up(reg, folder) {
        f = reg.folders.get(fid, None);
        if f is not None and f.visibility != "inherit" {
            return f.visibility;
        }
    }
    return "restricted";
}

def ancestor_folders(reg: FolderTree, folder: str) -> list[str] {
    chain = _walk_up(reg, folder);
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

test "folder visibility walk" {
    reg = load_folders(
        {"root": None, "team": "root", "docs": "team"},
        {"root": "workspace", "team": "inherit", "docs": "inherit"},
    );
    assert effective_visibility(reg, "docs") == "workspace";
    assert ancestor_folders(reg, "docs") == ["root", "team", "docs"];
}
