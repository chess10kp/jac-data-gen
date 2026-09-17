node Track {
    has tid: str;
    has path: str;
}

node Dir {
    has did: str;
    has path: str;
}

edge contains {
    has recursive: bool = False;
}

walker CollectTracks {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can scan with Dir entry {
        if here.did in self.claimed {
            skip;
        }
        self.claimed[here.did] = True;
        kids: list[Dir] = [];
        tracks: list[Track] = [];
        for ch in [here ->:contains:->] {
            if ch isa Track {
                tracks.append(ch);
            } else {
                kids.append(ch);
            }
        }
        for t in tracks {
            self.found.append(t.tid);
        }
        visit kids;
    }

    can scan_t with Track entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
    }
}

def collect_dir_tracks(top: Dir) -> list[str] {
    wk = top spawn CollectTracks(claimed={});
    return sorted(wk.found);
}

def add_recursive(root: Dir, subpath: str) -> list[str] {
    target: Dir | None = None;
    for ch in [root ->:contains:->][?:Dir] {
        if ch.path == subpath {
            target = ch;
            break;
        }
    }
    if target == None {
        return [];
    }
    return collect_dir_tracks(target);
}

test "recursive collection walks full tree" {
    root = Dir(did="d0", path="/music");
    d1 = Dir(did="d1", path="/music/rock");
    d2 = Dir(did="d2", path="/music/rock/live");
    t1 = Track(tid="t1", path="/music/a.mp3");
    t2 = Track(tid="t2", path="/music/rock/b.mp3");
    t3 = Track(tid="t3", path="/music/rock/live/c.mp3");
    root +>:contains:+> d1;
    root +>:contains:+> t1;
    d1 +>:contains:+> d2;
    d1 +>:contains:+> t2;
    d2 +>:contains:+> t3;
    assert collect_dir_tracks(root) == ["t1", "t2", "t3"];
}

test "diamond revisit counted once" {
    root = Dir(did="r", path="/");
    a = Dir(did="a", path="/a");
    b = Dir(did="b", path="/b");
    shared = Dir(did="s", path="/shared");
    t = Track(tid="x", path="/shared/x.mp3");
    root +>:contains:+> a;
    root +>:contains:+> b;
    a +>:contains:+> shared;
    b +>:contains:+> shared;
    shared +>:contains:+> t;
    got = collect_dir_tracks(root);
    assert len(got) == 1;
    assert got == ["x"];
}

test "unknown subpath tolerated with empty result" {
    root = Dir(did="r2", path="/m");
    t = Track(tid="q", path="/m/q.mp3");
    root +>:contains:+> t;
    assert add_recursive(root, "/nope") == [];
}

test "single track level only" {
    root = Dir(did="r3", path="/m");
    t1 = Track(tid="p1", path="/m/1.mp3");
    t2 = Track(tid="p2", path="/m/2.mp3");
    root +>:contains:+> t1;
    root +>:contains:+> t2;
    assert collect_dir_tracks(root) == ["p1", "p2"];
}

test "add_recursive descends nested subdir" {
    root = Dir(did="rr", path="/m");
    sub = Dir(did="ss", path="/m/sub");
    deep = Dir(did="dd", path="/m/sub/deep");
    ta = Track(tid="z1", path="/m/sub/a.flac");
    tb = Track(tid="z2", path="/m/sub/deep/b.flac");
    root +>:contains:+> sub;
    sub +>:contains:+> deep;
    sub +>:contains:+> ta;
    deep +>:contains:+> tb;
    assert add_recursive(root, "/m/sub") == ["z1", "z2"];
}
