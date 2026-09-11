"""Filesystem tree navigation.

Files and directories form a tree through ``parent`` / ``children``
pointers. Path resolution recursively ascends to the mount root;
size and extension queries recursively descend through directories.
"""


class FileNode:
    def __init__(self, name, is_dir, size=0):
        self.name = name
        self.is_dir = is_dir
        self.size = size         # bytes; 0 for directories
        self.parent = None       # FileNode | None (mount root)
        self.children = []       # list[FileNode]


def create(parent, name, is_dir, size=0):
    """Create a node under ``parent`` (None for the mount root)."""
    node = FileNode(name, is_dir, size)
    if parent is not None:
        node.parent = parent
        parent.children.append(node)
    return node


def path_of(node):
    """Absolute path of ``node``, ascending to the mount root."""
    if node.parent is None:
        return "/" + node.name
    return path_of(node.parent) + "/" + node.name


def dir_size(node):
    """Total bytes in ``node``'s subtree."""
    total = node.size
    for c in node.children:
        total += dir_size(c)
    return total


def files_under(node, ext):
    """Names of regular files under ``node`` whose name ends with ``ext``."""
    found = []
    if not node.is_dir and node.name.endswith(ext):
        found.append(node.name)
    for c in node.children:
        found.extend(files_under(c, ext))
    return sorted(found)


def deepest_dir(node):
    """Longest directory-only chain starting at ``node`` (files count 0)."""
    best = 0
    for c in node.children:
        candidate = deepest_dir(c)
        if candidate > best:
            best = candidate
    own = 1 if node.is_dir else 0
    return own + best
