"""tramhao/termusic#103 — recursive library track collection."""

glob TRACK_EXTS: list[str] = [".mp3", ".flac", ".ogg"];

node Library {
    has nodes: dict[str, Dir | Track] = {};
}

node Dir {
    has cid: str;
    has name: str;
}

node Track {
    has cid: str;
    has path: str;
}

edge Contains {}
edge Symlink {}

walker CollectTracks {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Dir entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("dir", here.cid);
        for ch in [here ->:Contains:->][?:Track] {
            self.found.append(ch.cid);
            print("track", ch.cid);
        }
        next_dirs: list[Dir] = [];
        for ch in [here ->:Contains:->][?:Dir] {
            next_dirs.append(ch);
        }
        for ch in [here ->:Symlink:->][?:Dir] {
            next_dirs.append(ch);
        }
        for nd in next_dirs {
            visit :0: [nd];
        }
    }
}

def put_dir(lib: Library, d: Dir) -> None {
    lib.nodes[d.cid] = d;
}

def put_track(lib: Library, t: Track) -> None {
    lib.nodes[t.cid] = t;
}

def connect_contains(parent: Dir, child: Dir | Track) -> None {
    parent +>:Contains:+> child;
}

def connect_symlink(src: Dir, target: Dir) -> None {
    src +>:Symlink:+> target;
}

def collect_tracks_recursive(lib: Library, dir_id: str) -> list[str] {
    if dir_id not in lib.nodes {
        return [];
    }
    start = lib.nodes[dir_id];
    if not (start is Dir) {
        return [];
    }
    wk = start spawn CollectTracks(claimed={});
    out: list[str] = [];
    for tid in wk.found {
        out.append(tid);
    }
    return sorted(out);
}

def add_directory_tracks_to_playlist(
    lib: Library, dir_id: str, playlist: list[str]
) -> list[str] {
    tracks = collect_tracks_recursive(lib, dir_id);
    added: list[str] = [];
    for tid in tracks {
        dup = False;
        for existing in playlist {
            if existing == tid {
                dup = True;
                break;
            }
        }
        if not dup {
            playlist.append(tid);
            added.append(tid);
        }
    }
    return added;
}

with entry {
    lib = Library(nodes={});
    graph_root = Dir(cid="demo_root", name="library");
    root ++> graph_root;
    put_dir(lib, graph_root);
    nested = Dir(cid="demo_nested", name="albums");
    connect_contains(graph_root, nested);
    put_dir(lib, nested);
    t1 = Track(cid="demo_t1", path="/library/song.mp3");
    t2 = Track(cid="demo_t2", path="/library/albums/deep.flac");
    connect_contains(graph_root, t1);
    put_track(lib, t1);
    connect_contains(nested, t2);
    put_track(lib, t2);
    wk = graph_root spawn CollectTracks(claimed={});
    print("demo_collected", sorted(wk.found));
}

test "nested_directories_collect_recursively" {
    lib = Library(nodes={});
    graph_root = Dir(cid="root", name="library");
    root ++> graph_root;
    put_dir(lib, graph_root);
    nested = Dir(cid="nested", name="albums");
    connect_contains(graph_root, nested);
    put_dir(lib, nested);
    ta = Track(cid="a", path="/library/a.mp3");
    tb = Track(cid="b", path="/library/albums/b.flac");
    connect_contains(graph_root, ta);
    put_track(lib, ta);
    connect_contains(nested, tb);
    put_track(lib, tb);
    got = collect_tracks_recursive(lib, "root");
    assert got == ["a", "b"];
}

test "diamond revisit does not duplicate tracks" {
    lib = Library(nodes={});
    graph_root = Dir(cid="root", name="root");
    root ++> graph_root;
    put_dir(lib, graph_root);
    d1 = Dir(cid="d1", name="left");
    d2 = Dir(cid="d2", name="right");
    mid = Dir(cid="mid", name="shared");
    connect_contains(graph_root, d1);
    connect_contains(graph_root, d2);
    put_dir(lib, d1);
    put_dir(lib, d2);
    put_dir(lib, mid);
    connect_contains(d1, mid);
    connect_contains(d2, mid);
    t1 = Track(cid="t1", path="/shared/t1.ogg");
    connect_contains(mid, t1);
    put_track(lib, t1);
    got = collect_tracks_recursive(lib, "root");
    assert got == ["t1"];
}

test "symlink cycle terminates without duplicate tracks" {
    lib = Library(nodes={});
    graph_root = Dir(cid="root", name="root");
    root ++> graph_root;
    put_dir(lib, graph_root);
    sub = Dir(cid="sub", name="sub");
    connect_contains(graph_root, sub);
    put_dir(lib, sub);
    tx = Track(cid="tx", path="/root/tx.mp3");
    connect_contains(graph_root, tx);
    put_track(lib, tx);
    connect_symlink(graph_root, sub);
    connect_symlink(sub, graph_root);
    got = collect_tracks_recursive(lib, "root");
    assert got == ["tx"];
}

test "playlist add skips existing entries" {
    lib = Library(nodes={});
    graph_root = Dir(cid="root", name="root");
    root ++> graph_root;
    put_dir(lib, graph_root);
    tx = Track(cid="x", path="/x.mp3");
    ty = Track(cid="y", path="/y.mp3");
    tz = Track(cid="z", path="/z.mp3");
    connect_contains(graph_root, tx);
    connect_contains(graph_root, ty);
    connect_contains(graph_root, tz);
    put_track(lib, tx);
    put_track(lib, ty);
    put_track(lib, tz);
    playlist: list[str] = ["x", "y"];
    added = add_directory_tracks_to_playlist(lib, "root", playlist);
    assert added == ["z"];
    assert playlist == ["x", "y", "z"];
}

test "unknown dir returns empty" {
    lib = Library(nodes={});
    assert collect_tracks_recursive(lib, "missing") == [];
}

test "non dir start returns empty" {
    lib = Library(nodes={});
    t0 = Track(cid="t0", path="/t0.mp3");
    put_track(lib, t0);
    assert collect_tracks_recursive(lib, "t0") == [];
}
