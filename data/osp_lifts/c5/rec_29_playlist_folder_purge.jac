"""Idiomatic OSP lift: playlist folder purge (category C5, two-phase §5.5).

Phase COLLECT -- `PurgeScan` walks `Folders` edges (folder -> subfolder)
and gathers doomed folders/playlists into typed `has` fields. A node
filed under more than one live folder (`holders > 1`) is a shared
boundary: spared with everything beneath it, siblings continue (`skip;`).
The seen-guard is the once-only diamond guard and the explicit cycle
policy -- 0.36.1 has no built-in dedup.

Phase APPLY -- outside any walk: dying folders release their holds, doomed
nodes are disconnected and destroyed. Kept semantics: even the requested
root is spared when shared; unknown ids are a silent no-op.
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
