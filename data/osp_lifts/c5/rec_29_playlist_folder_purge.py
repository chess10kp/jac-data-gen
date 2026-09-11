"""Playlist library with cascading folder purge.

Folders contain subfolders and playlists. A playlist may be filed under
several folders at once; purging a folder destroys the folder tree and
every playlist EXCLUSIVELY filed inside it -- playlists still held by any
surviving folder are detached from the doomed ones and live on. Unknown
ids are a silent no-op; re-purging reports nothing.
"""


class LibNode:
    def __init__(self, node_id, kind, label):
        self.node_id = node_id
        self.kind = kind            # "folder" | "playlist"
        self.label = label
        self.children = []          # child node_ids (folders only)
        self.holders = 0            # how many folders file this node


class PlaylistLibrary:
    def __init__(self):
        self.nodes = {}             # node_id -> LibNode

    def add_folder(self, node_id, label):
        self.nodes[node_id] = LibNode(node_id, "folder", label)
        return self.nodes[node_id]

    def add_playlist(self, node_id, label):
        self.nodes[node_id] = LibNode(node_id, "playlist", label)
        return self.nodes[node_id]

    def file_under(self, parent_id, child_id):
        if child_id not in self.nodes or parent_id not in self.nodes:
            return False            # tolerate unknown refs
        self.nodes[parent_id].children.append(child_id)
        self.nodes[child_id].holders += 1
        return True

    def _collect(self, node_id, doomed_folders, doomed_playlists, spared):
        """Recursive descent; once-only guard for multi-filed nodes."""
        if node_id in doomed_folders or node_id in spared:
            return
        if node_id not in self.nodes:
            return                  # stale reference tolerated
        node = self.nodes[node_id]
        if node.holders > 1:
            spared.append(node)     # filed elsewhere too: keep it
            return
        if node.kind == "playlist":
            doomed_playlists.append(node)
            return
        doomed_folders.append(node)
        for child_id in node.children:
            self._collect(child_id, doomed_folders, doomed_playlists,
                          spared)

    def purge_folder(self, folder_id):
        """Destroy *folder_id*, subfolders and exclusively-filed playlists.

        Returns sorted ids of surviving (spared) nodes. Unknown ids [].
        """
        if folder_id not in self.nodes:
            return []
        root = self.nodes[folder_id]
        doomed_folders, doomed_playlists, spared = [], [], []
        if root.holders > 1:
            spared.append(root)     # even the requested node may be shared
        else:
            doomed_folders.append(root)
            for child_id in root.children:
                self._collect(child_id, doomed_folders, doomed_playlists,
                              spared)
        for dead in doomed_folders:
            for child_id in dead.children:
                if child_id in self.nodes:
                    self.nodes[child_id].holders -= 1
            del self.nodes[dead.node_id]
        for dead in doomed_playlists:
            del self.nodes[dead.node_id]
        return sorted(s.node_id for s in spared)

    def exists(self, node_id):
        return node_id in self.nodes

    def labels(self):
        return sorted(n.label for n in self.nodes.values())


if __name__ == "__main__":
    lib = PlaylistLibrary()
    lib.add_folder("root", "Root")
    lib.add_folder("chill", "Chill")
    lib.add_playlist("lofi", "Lo-Fi")
    assert lib.file_under("root", "chill")
    assert lib.file_under("chill", "lofi")
    print(lib.purge_folder("root"), lib.labels())
