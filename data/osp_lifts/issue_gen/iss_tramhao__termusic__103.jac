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
