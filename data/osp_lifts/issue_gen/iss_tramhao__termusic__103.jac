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
