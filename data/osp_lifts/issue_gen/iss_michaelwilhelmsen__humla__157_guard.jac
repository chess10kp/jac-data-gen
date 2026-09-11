"""michaelwilhelmsen/humla#157 — candidate + hidden guards."""

obj FolderStore { has stamp: int = 0; }
node Folder { has path: str; }
edge InFolder {}

walker AncestorWalk {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can begin with Root entry {
        matches = [root-->][?:Folder, path == self.origin];
        if not matches { disengage; }
        parents = [matches[0] <-:InFolder:<-][?:Folder];
        if parents { visit parents; } else { disengage; }
    }

    can climb with Folder entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        self.hits.append(here.path);
        parents = [here <-:InFolder:<-][?:Folder];
        if parents { visit parents; } else { disengage; }
    }
}

walker SubtreeWalk {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can begin with Root entry {
        matches = [root-->][?:Folder, path == self.origin];
        if not matches { disengage; }
        kids = [matches[0] ->:InFolder:->][?:Folder];
        if kids { visit kids; } else { disengage; }
    }

    can step with Folder entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        self.hits.append(here.path);
        visit [->:InFolder:->][?:Folder];
    }
}

def _find(path: str) -> Folder | None {
    for f in [-->][?:Folder] { if f.path == path { return f; } }
    return None;
}

def load_folders(specs: list[tuple[str, str | None]]) -> FolderStore {
    mp: dict[str, Folder] = {};
    for (p, _par) in specs {
        if p not in mp { n = Folder(path=p); root ++> n; mp[p] = n; }
    }
    for (p, par) in specs {
        if par is not None {
            parent = mp.get(par, None);
            child = mp.get(p, None);
            if parent is not None and child is not None { parent +>:InFolder:+> child; }
        }
    }
    return FolderStore(stamp=1);
}

def resolve_path(g: FolderStore, path: str) -> str | None {
    _ = g;
    if not path { return None; }
    p = path;
    if not p.startswith("/") { p = "/" + p; }
    if len(p) > 1 { p = p.rstrip("/"); }
    f = _find(p);
    if f is None { return None; }
    return f.path;
}

def list_children(g: FolderStore, folder: str) -> list[str] {
    _ = g;
    fp = resolve_path(g, folder);
    if fp is None { return []; }
    f = _find(fp);
    if f is None { return []; }
    return sorted([c.path for c in [f ->:InFolder:->][?:Folder]]);
}

def mkdir(g: FolderStore, parent: str, name: str) -> str | None {
    _ = g;
    par = resolve_path(g, parent);
    if par is None { return None; }
    child_path = ("/" + name.strip("/")) if par == "/" else par + "/" + name.strip("/");
    if _find(child_path) is not None { raise ValueError(f"duplicate: {child_path}"); }
    ch = Folder(path=child_path);
    root ++> ch;
    pnode = _find(par);
    if pnode is not None { pnode +>:InFolder:+> ch; }
    return child_path;
}

def subtree_paths(g: FolderStore, folder: str) -> list[str] {
    _ = g;
    fp = resolve_path(g, folder);
    if fp is None { return []; }
    w = root spawn SubtreeWalk(origin=fp, claimed={}, hits=[]);
    return sorted(w.hits);
}

def would_reparent_cycle(g: FolderStore, folder: str, new_parent: str | None) -> bool {
    _ = g;
    fp = resolve_path(g, folder);
    if fp is None { raise KeyError(folder); }
    if new_parent is None { return False; }
    np = resolve_path(g, new_parent);
    if np is None { raise KeyError(new_parent); }
    if np == fp { return True; }
    w = root spawn AncestorWalk(origin=np, claimed={}, hits=[]);
    return fp in w.hits;
}

def reparent(g: FolderStore, folder: str, new_parent: str | None) -> None {
    _ = g;
    fp = resolve_path(g, folder);
    if fp is None { raise KeyError(folder); }
    if new_parent is not None and would_reparent_cycle(g, folder, new_parent) {
        raise ValueError("cycle");
    }
    fold = _find(fp);
    if fold is None { return; }
    for old in [fold <-:InFolder:<-][?:Folder] {
        old del ->:InFolder:-> fold;
    }
    if new_parent is not None {
        par = _find(new_parent);
        if par is None { raise KeyError(new_parent); }
        par +>:InFolder:+> fold;
    }
}

test "folder tree main" {
    g = load_folders([
        ("/", None),
        ("/personal", "/"),
        ("/personal/notes", "/personal"),
        ("/work", "/"),
        ("/work/projects", "/work"),
    ]);
    assert resolve_path(g, "/personal/notes") == "/personal/notes";
    assert list_children(g, "/personal") == ["/personal/notes"];
    assert subtree_paths(g, "/") == [
        "/personal", "/personal/notes", "/work", "/work/projects",
    ];
    assert mkdir(g, "/work", "archive") == "/work/archive";
    assert would_reparent_cycle(g, "/personal", "/personal/notes") is True;
    try {
        reparent(g, "/personal", "/personal/notes");
        assert False;
    } except ValueError {
        # expected
    }
    reparent(g, "/work/projects", "/personal");
    assert list_children(g, "/personal") == ["/personal/notes", "/work/projects"];
}

test "unknown folder tolerance" {
    g = load_folders([("/", None), ("/solo", "/")]);
    assert resolve_path(g, "/nope") is None;
    assert list_children(g, "/nope") == [];
    assert subtree_paths(g, "/nope") == [];
    assert mkdir(g, "/nope", "x") is None;
}

test "subtree adversarial breadth" {
    g = load_folders([
        ("/", None),
        ("/a", "/"),
        ("/b", "/"),
        ("/c", "/"),
        ("/a/x", "/a"),
        ("/b/y", "/b"),
        ("/c/z", "/c"),
        ("/a/x/deep", "/a/x"),
    ]);
    assert subtree_paths(g, "/") == [
        "/a", "/a/x", "/a/x/deep", "/b", "/b/y", "/c", "/c/z",
    ];
}
