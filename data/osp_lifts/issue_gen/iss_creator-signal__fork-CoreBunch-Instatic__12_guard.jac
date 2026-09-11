"""creator-signal/fork-CoreBunch-Instatic#12 — candidate + guards."""
obj FsGraph { has stamp: int = 0; }
node FsNode { has path: str; has kind: str; }
edge InFolder {}

walker MediaWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    can step with FsNode entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.kind == "file" {
            if here.path.endswith(".png") or here.path.endswith(".mp4") { self.hits.append(here.path); }
            disengage;
        }
        visit [->:InFolder:->][?:FsNode] else { disengage; };
    }
}

def _find(path: str) -> FsNode | None {
    for n in [-->][?:FsNode] { if n.path == path { return n; } }
    return None;
}

def load_fs(entries: list[tuple[str, str, str | None]]) -> FsGraph {
    mp: dict[str, FsNode] = {};
    for (p, k, _par) in entries {
        if p not in mp { n = FsNode(path=p, kind=k); root ++> n; mp[p] = n; }
    }
    for (p, _k, par) in entries {
        if par is not None {
            parent = mp.get(par, None); child = mp.get(p, None);
            if parent is not None and child is not None { parent +>:InFolder:+> child; }
        }
    }
    return FsGraph(stamp=1);
}

def list_media(g: FsGraph, root_path: str) -> list[str] {
    _ = g;
    anchor = _find(root_path);
    if anchor is None or anchor.kind != "folder" { return []; }
    w = anchor spawn MediaWalk(claimed={}, hits=[]);
    return sorted(w.hits);
}

def upload_queue(g: FsGraph, drops: list[str]) -> list[str] {
    _ = g;
    acc: dict[str, bool] = {};
    for drop in sorted(drops) { for p in list_media(g, drop) { acc[p] = True; } }
    return sorted(acc.keys());
}

test "media recursive" {
    g = load_fs([
        ("/m", "folder", None), ("/m/a.png", "file", "/m"), ("/m/sub", "folder", "/m"),
        ("/m/sub/b.mp4", "file", "/m/sub"),
    ]);
    assert list_media(g, "/m") == ["/m/a.png", "/m/sub/b.mp4"];
    assert upload_queue(g, ["/m"]) == ["/m/a.png", "/m/sub/b.mp4"];
}

test "diamond folder revisit" {
    g = load_fs([
        ("/r", "folder", None), ("/r/x", "folder", "/r"), ("/r/y", "folder", "/r"),
        ("/r/z.png", "file", "/r/x"), ("/r/z.png", "file", "/r/y"),
    ]);
    assert list_media(g, "/r") == ["/r/z.png"];
}
