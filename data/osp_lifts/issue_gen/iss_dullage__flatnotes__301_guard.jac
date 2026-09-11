"""dullage/flatnotes#301 — candidate + hidden guards."""

obj VfsStore { has stamp: int = 0; }
node FsEntry { has path: str; has kind: str; }
edge InDir {}

walker MdIndex {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with FsEntry entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.kind == "file" {
            if here.path.endswith(".md") { self.hits.append(here.path); }
            disengage;
        }
        visit [->:InDir:->][?:FsEntry] else { disengage; };
    }
}

def _find(path: str) -> FsEntry | None {
    for ent in [-->][?:FsEntry] { if ent.path == path { return ent; } }
    return None;
}

def load_vfs(entries: list[tuple[str, str, str | None]]) -> VfsStore {
    mp: dict[str, FsEntry] = {};
    for (p, k, _par) in entries {
        if p not in mp {
            fresh = FsEntry(path=p, kind=k);
            root ++> fresh;
            mp[p] = fresh;
        }
    }
    for (p, k, par) in entries {
        cur = mp.get(p, None);
        if cur is not None { cur.kind = k; }
        if par is not None {
            parent = mp.get(par, None);
            child = mp.get(p, None);
            if parent is not None and child is not None {
                parent +>:InDir:+> child;
            }
        }
    }
    return VfsStore(stamp=1);
}

def index_markdown(g: VfsStore, `root: str) -> list[str] {
    _ = g;
    anchor = _find(`root);
    if anchor is None or anchor.kind != "folder" { return []; }
    w = anchor spawn MdIndex(claimed={}, hits=[]);
    return sorted(w.hits);
}

test "recursive markdown index main" {
    g = load_vfs([
        ("/notes", "folder", None),
        ("/notes/readme.md", "file", "/notes"),
        ("/notes/guide", "folder", "/notes"),
        ("/notes/guide/intro.md", "file", "/notes/guide"),
        ("/notes/guide/advanced.md", "file", "/notes/guide"),
        ("/notes/assets/logo.png", "file", "/notes"),
    ]);
    assert index_markdown(g, "/notes") == [
        "/notes/guide/advanced.md",
        "/notes/guide/intro.md",
        "/notes/readme.md",
    ];
    assert index_markdown(g, "/notes/guide") == [
        "/notes/guide/advanced.md",
        "/notes/guide/intro.md",
    ];
    assert index_markdown(g, "/notes/guide/intro.md") == [];
}

test "unknown root tolerance" {
    g = load_vfs([("/solo", "folder", None)]);
    assert index_markdown(g, "/nope") == [];
}

test "cycle revisit before deep closure" {
    g = load_vfs([
        ("/a", "folder", None),
        ("/b", "folder", "/a"),
        ("/c", "folder", "/b"),
        ("/notes/hidden.md", "file", "/c"),
        ("/a", "folder", "/c"),
    ]);
    assert index_markdown(g, "/a") == ["/notes/hidden.md"];
}

test "adversarial breadth sibling markdown" {
    g = load_vfs([
        ("/vault", "folder", None),
        ("/vault/w1", "folder", "/vault"),
        ("/vault/w1/a.md", "file", "/vault/w1"),
        ("/vault/w2", "folder", "/vault"),
        ("/vault/w2/b.md", "file", "/vault/w2"),
        ("/vault/w3", "folder", "/vault"),
        ("/vault/w3/c.md", "file", "/vault/w3"),
        ("/vault/w1/deep", "folder", "/vault/w1"),
        ("/vault/w1/deep/nested.md", "file", "/vault/w1/deep"),
    ]);
    assert index_markdown(g, "/vault") == [
        "/vault/w1/a.md",
        "/vault/w1/deep/nested.md",
        "/vault/w2/b.md",
        "/vault/w3/c.md",
    ];
}
