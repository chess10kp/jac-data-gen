"""In-memory virtual filesystem with recursive subtree deletion.

Directories are ``Node`` objects holding children in plain lists. A child
may be mounted under more than one parent (bind-mount alias), so every node
carries a reference count. Deleting a branch detaches the dying mounts and
destroys a node only when its last mount disappears. The cascade stops at
shared boundaries -- an aliased node survives, together with everything
below it; unknown paths are a silent no-op (callers race other deleters).
"""


class Node:
    def __init__(self, name, is_dir=False):
        self.name = name
        self.is_dir = is_dir
        self.children = []   # direct children; a node may sit under >1 parent
        self.links = 0       # how many parent entries currently point here


class FileSystem:
    def __init__(self):
        self.root = Node("/", is_dir=True)
        self.root.links = 1
        self.index = {"/": self.root}          # path -> node registry

    def _create(self, path, is_dir):
        parent_path, _, name = path.rpartition("/")
        parent = self.index[parent_path or "/"]
        node = Node(name, is_dir=is_dir)
        parent.children.append(node)
        node.links += 1
        self.index[path] = node
        return node

    def mkdir(self, path):
        return self._create(path, is_dir=True)

    def touch(self, path):
        return self._create(path, is_dir=False)

    def mount(self, src_path, dest_parent_path, alias):
        """Bind-mount an existing node under another directory."""
        src = self.index[src_path]
        dest_parent = self.index[dest_parent_path]
        dest_parent.children.append(src)
        src.links += 1
        self.index[dest_parent_path + "/" + alias] = src

    def _collect(self, node, visited, doomed, spared):
        """Recursive descent gathering the closure below *node*.

        Once-only guard: a node reached twice is collected once. A node with
        more than one live mount is a shared boundary -- it is spared, with
        its whole subtree, and merely detached from the dying branch.
        """
        if id(node) in visited:
            return
        visited.add(id(node))
        if node.links > 1:
            spared.append(node)
            return
        doomed.append(node)
        for child in node.children:
            self._collect(child, visited, doomed, spared)

    def delete_subtree(self, path):
        """Delete the entry at *path*.

        Destroys the exclusive subtree beneath it, detaches shared-boundary
        nodes instead of destroying them, and returns how many nodes were
        destroyed. Unknown paths are a silent no-op; deleting ``/`` raises.
        """
        target = self.index.get(path)
        if target is None:
            return 0
        if target is self.root:
            raise ValueError("refusing to delete the filesystem root")
        doomed, spared = [], []
        self._collect(target, set(), doomed, spared)
        # Detach the requested mount first (the parent itself survives).
        parent = self.index[path.rpartition("/")[0] or "/"]
        if target in spared:
            parent.children.remove(target)
            target.links -= 1
            return 0
        # Dying mounts: every entry held by a doomed node goes away with it,
        # so each referenced child loses exactly one reference count.
        for holder in doomed:
            for child in holder.children:
                child.links -= 1
            holder.children = []
        dead_paths = [p for p, n in self.index.items() if n in doomed]
        for p in dead_paths:
            del self.index[p]
        return len(doomed)

    def ls(self, path):
        entry = self.index.get(path)
        if entry is None:
            return None
        return sorted(c.name for c in entry.children)

    def exists(self, path):
        return path in self.index
