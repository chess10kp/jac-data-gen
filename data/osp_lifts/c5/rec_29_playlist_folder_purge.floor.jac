"""Playlist library with cascading folder purge.

Folders contain subfolders and playlists. A playlist may be filed under
several folders at once; purging a folder destroys the folder tree and
every playlist EXCLUSIVELY filed inside it -- playlists still held by any
surviving folder are detached from the doomed ones and live on. Unknown
ids are a silent no-op; re-purging reports nothing.
"""
class LibNode {
    has node_id: str;
    has kind: str;
    has label: str;
    has children: list[str] = [];
    has holders: int = 0;
    def init(self: LibNode, node_id: str, kind: str, label: str) -> object {
        self.node_id = node_id;
        self.kind = kind;
        self.label = label;
        self.children = [];
        self.holders = 0;
    }
}
class PlaylistLibrary {
    has nodes: dict[str, LibNode];
    def init(self: PlaylistLibrary) -> object {
        self.nodes = {};
    }
    def add_folder(self: PlaylistLibrary, node_id: str, label: str) -> object {
        self.nodes[node_id] = LibNode(node_id, "folder", label);
        return self.nodes[node_id];
    }
    def add_playlist(self: PlaylistLibrary, node_id: str, label: str) -> object {
        self.nodes[node_id] = LibNode(node_id, "playlist", label);
        return self.nodes[node_id];
    }
    def file_under(self: PlaylistLibrary, parent_id: str, child_id: str) -> object {
        if ((child_id not in self.nodes) or (parent_id not in self.nodes)) {
            return False;
        }
        self.nodes[parent_id].children.append(child_id);
        self.nodes[child_id].holders += 1;
        return True;
    }
    def _collect(
        self: PlaylistLibrary,
        node_id: str,
        doomed_folders: list[LibNode],
        doomed_playlists: list[LibNode],
        spared: list[LibNode]
    ) -> object {
        if ((node_id in doomed_folders) or (node_id in spared)) {
            return;
        }
        if (node_id not in self.nodes) {
            return;
        }
        nd = self.nodes[node_id];
        if (nd.holders > 1) {
            spared.append(nd);
            return;
        }
        if (nd.kind == "playlist") {
            doomed_playlists.append(nd);
            return;
        }
        doomed_folders.append(nd);
        for child_id in nd.children {
            self._collect(child_id, doomed_folders, doomed_playlists, spared);
        }
    }
    def purge_folder(self: PlaylistLibrary, folder_id: str) -> object {
        if (folder_id not in self.nodes) {
            return [];
        }
        `root = self.nodes[folder_id];
        (doomed_folders, doomed_playlists, spared) = ([], [], []);
        if (`root.holders > 1) {
            spared.append(`root);
        } else {
            doomed_folders.append(`root);
            for child_id in `root.children {
                self._collect(child_id, doomed_folders, doomed_playlists, spared);
            }
        }
        for dead in doomed_folders {
            for child_id in dead.children {
                if (child_id in self.nodes) {
                    self.nodes[child_id].holders -= 1;
                }
            }
            delete(self.nodes[dead.node_id],);
        }
        for dead in doomed_playlists {
            delete(self.nodes[dead.node_id],);
        }
        return sorted(s.node_id for s in spared);
    }

    def exists(self: PlaylistLibrary, node_id: str) -> object {
        return (node_id in self.nodes);
    }
    def labels(self: PlaylistLibrary) -> object {
        return sorted(n.label for n in self.nodes.values());
    }
}

with entry {
    if (__name__ == "__main__") {
        lib = PlaylistLibrary();
        lib.add_folder("root", "Root");
        lib.add_folder("chill", "Chill");
        lib.add_playlist("lofi", "Lo-Fi");
        assert lib.file_under("root", "chill");
        assert lib.file_under("chill", "lofi");
        print(lib.purge_folder("root"), lib.labels());
    }
}

