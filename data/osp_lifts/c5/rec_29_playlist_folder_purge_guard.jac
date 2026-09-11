"""Guard for rec_29_playlist_folder_purge -- candidate OSP lift inlined
verbatim (same-prefix sibling imports are unreliable across jac's native
seam), plus behavioral tests: folder-tree purge sparing a multi-filed
playlist, shared playlist destroyed with its last holder, stale/unknown
reference tolerance.
"""


node LibNode {
    has node_id: str;
    has label: str;
    has kind: str;              # "folder" | "playlist"
    has holders: int = 0;
}

edge Folders { }

"""Split one folder subtree into doomed and spared nodes."""
walker PurgeScan {
    has doomed_folders: list[LibNode] = [];
    has doomed_playlists: list[LibNode] = [];
    has spared: list[LibNode] = [];
    has seen: dict[str, bool] = {};

    can scan with LibNode entry {
        if here.node_id in self.seen {
            skip;               # revisit / cycle policy: decide once only,
        }                       # keep sibling branches alive
        self.seen[here.node_id] = True;
        if here.holders > 1 {
            self.spared.append(here);   # filed elsewhere too: keep subtree
            skip;
        }
        if here.kind == "playlist" {
            self.doomed_playlists.append(here);
        } else {
            self.doomed_folders.append(here);
            visit [->:Folders:->];
        }
    }
}

obj PlaylistLibrary {
    has nodes: dict[str, LibNode];

    def add_folder(node_id: str, label: str) -> LibNode {
        fresh = LibNode(node_id=node_id, label=label, kind="folder");
        self.nodes[node_id] = fresh;
        return fresh;
    }

    def add_playlist(node_id: str, label: str) -> LibNode {
        fresh = LibNode(node_id=node_id, label=label, kind="playlist");
        self.nodes[node_id] = fresh;
        return fresh;
    }

    def file_under(parent_id: str, child_id: str) -> bool {
        parent = self.nodes.get(parent_id);
        child = self.nodes.get(child_id);
        if child is None or parent is None {
            return False;               # tolerate unknown refs
        }
        parent +>:Folders:+> child;
        child.holders += 1;
        return True;
    }

    """Destroy *folder_id* + exclusive contents; returns spared ids."""
    def purge_folder(folder_id: str) -> list[str] {
        top = self.nodes.get(folder_id);
        if top is None {
            return [];
        }
        # Phase COLLECT -- decide the purge set without mutating.
        scan = top spawn PurgeScan();
        spared_ids: list[str] = [s.node_id for s in scan.spared];
        doomed = scan.doomed_folders + scan.doomed_playlists;

        # Phase APPLY -- mutation strictly after the walk finished.
        for dead in scan.doomed_folders {
            kids = [dead ->:Folders:->] as list[LibNode];
            for child in kids {
                child.holders -= 1;     # dying folder releases its filing
                dead del ->:Folders:-> child;
            }
        }
        for victim in doomed {
            vid = victim.node_id;       # capture before del unbinds
            del victim;
            _gone = self.nodes.pop(vid, None);
        }
        return sorted(spared_ids);
    }

    def exists(node_id: str) -> bool {
        return node_id in self.nodes;
    }

    def labels -> list[str] {
        return sorted(n.label for n in self.nodes.values());
    }
}

"""Build a fresh deterministic library; creation order = fixture order."""
def load_graph(spec: list[tuple[str, str, str]],
               links: list[tuple[str, str]]) -> PlaylistLibrary {
    lib = PlaylistLibrary(nodes={});
    for row in spec {
        if row[1] == "folder" {
            _made = lib.add_folder(row[0], row[2]);
        } else {
            _made = lib.add_playlist(row[0], row[2]);
        }
    }
    for pair in links {
        _ok = lib.file_under(pair[0], pair[1]);
    }
    return lib;
}

test "purge_spared_shared_playlist" {
    lib = load_graph(
        spec=[("work", "folder", "Work"), ("focus", "folder", "Focus"),
              ("gym", "folder", "Gym"), ("lofi", "playlist", "Lo-Fi"),
              ("party", "folder", "Party"), ("bangers", "playlist", "Bangers")],
        links=[("work", "focus"), ("work", "gym"), ("focus", "lofi"),
               ("party", "lofi"), ("party", "bangers")]
    );
    spared = lib.purge_folder("work");
    assert spared == ["lofi"];          # filed under party too
    assert not lib.exists("work");
    assert not lib.exists("focus") and not lib.exists("gym");
    assert lib.exists("lofi") and lib.exists("party");
}

test "shared_playlist_dies_with_last_folder" {
    lib = load_graph(
        spec=[("work", "folder", "Work"), ("focus", "folder", "Focus"),
              ("lofi", "playlist", "Lo-Fi"), ("party", "folder", "Party"),
              ("bangers", "playlist", "Bangers")],
        links=[("work", "focus"), ("focus", "lofi"), ("party", "lofi"),
               ("party", "bangers")]
    );
    _s1 = lib.purge_folder("party");
    assert not lib.exists("bangers") and lib.exists("lofi");
    s2 = lib.purge_folder("work");      # last holder gone -> destroyed
    assert s2 == [];
    assert not lib.exists("lofi");
}

test "unknown_and_stale_refs_tolerated" {
    lib = load_graph(
        spec=[("a", "folder", "A"), ("p1", "playlist", "P1")],
        links=[("a", "p1")]
    );
    assert lib.purge_folder("ghost") == [];
    ok = lib.file_under("a", "ghost");   # unknown child refused
    assert ok is False;
    spared = lib.purge_folder("a");
    assert spared == [];
    assert not lib.exists("p1");
}
