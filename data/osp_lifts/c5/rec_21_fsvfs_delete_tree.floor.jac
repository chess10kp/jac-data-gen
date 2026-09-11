"""In-memory virtual filesystem with recursive subtree deletion.

Directories are ``Node`` objects holding children in plain lists. A child
may be mounted under more than one parent (bind-mount alias), so every node
carries a reference count. Deleting a branch detaches the dying mounts and
destroys a node only when its last mount disappears. The cascade stops at
shared boundaries -- an aliased node survives, together with everything
below it; unknown paths are a silent no-op (callers race other deleters).
"""
class Node {
    has name: str;
    has is_dir: bool = False;
    has children: list[Node] = [];
    has links: int = 0;
    def init(self: Node, name: str, is_dir: bool = False) -> object {
        self.name = name;
        self.is_dir = is_dir;
        self.children = [];
        self.links = 0;
    }
}
class FileSystem {
    has root_dir: Node;
    has index: dict[str, Node];
    def init(self: FileSystem) -> object {
        self.root_dir = Node("/", is_dir=True);
        self.root_dir.links = 1;
        self.index = {"/": self.root_dir};
    }
    def _create(self: FileSystem, path: str, is_dir: bool) -> object {
        (parent_path, _, name) = path.rpartition("/");
        parent = self.index[(parent_path or "/")];
        item = Node(name, is_dir=is_dir);
        parent.children.append(item);
        item.links += 1;
        self.index[path] = item;
        return item;
    }
    def mkdir(self: FileSystem, path: str) -> object {
        return self._create(path, is_dir=True);
    }
    def touch(self: FileSystem, path: str) -> object {
        return self._create(path, is_dir=False);
    }
    def mount(
        self: FileSystem, src_path: str, dest_parent_path: str, alias: str
    ) -> object {
        src = self.index[src_path];
        dest_parent = self.index[dest_parent_path];
        dest_parent.children.append(src);
        src.links += 1;
        self.index[(dest_parent_path + "/" + alias)] = src;
    }
    def _collect(
        self: FileSystem, item: Node, visited: set[int], doomed: list[Node], spared: list[Node]
    ) -> object {
        if (id(item) in visited) {
            return;
        }
        visited.add(id(item));
        if (item.links > 1) {
            spared.append(item);
            return;
        }
        doomed.append(item);
        for child in item.children {
            self._collect(child, visited, doomed, spared);
        }
    }

    def delete_subtree(self: FileSystem, path: str) -> object {
        target = self.index.get(path);
        if (target is None) {
            return 0;
        }
        if (target is self.root_dir) {
            raise ValueError("refusing to delete the filesystem root");
        }
        (doomed, spared) = ([], []);
        self._collect(target, set(), doomed, spared);
        parent = self.index[(path.rpartition("/")[0] or "/")];
        if (target in spared) {
            parent.children.remove(target);
            target.links -= 1;
            return 0;
        }
        for holder in doomed {
            kids = holder.children as list[Node];
            for child in kids {
                child.links -= 1;
            }
            holder.children = [];
        }
        dead_paths = [
            p
            for (p, n) in self.index.items()
            if (n in doomed)
        ];
        for p in dead_paths {
            _gone = self.index.pop(p, None);
        }
        return len(doomed);
    }

    def ls(self: FileSystem, path: str) -> object {
        ent = self.index.get(path);
        if (ent is None) {
            return None;
        }
        return sorted(c.name for c in ent.children);
    }
    def exists(self: FileSystem, path: str) -> object {
        return (path in self.index);
    }
}

