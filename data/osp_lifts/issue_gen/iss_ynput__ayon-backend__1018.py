"""Project entity index: folder paths, inheritance and cross-type chains.

Before-code synthesized from ynput/ayon-backend#1018: project data is split
per entity type (folders, tasks, products, versions), so cross-type queries
re-encode hierarchy logic over and over -- path building needs ancestor
joins, inherited attributes need folder walks, and "all versions under this
folder" chains through task and product links. The index keeps a parent
pointer map plus children adjacency for folders, and id-keyed link maps for
the cross-type chains.
"""


class EntityIndex:
    def __init__(self):
        self.folder_parent = {}   # folder -> parent folder | None
        self.folder_children = {} # folder -> [child folders]
        self.attr_values = {}     # folder -> {attr: value}
        self.task_folder = {}     # task -> folder it lives in
        self.product_task = {}    # product -> owning task
        self.version_product = {} # version -> owning product

    def add_folder(self, name, parent=None, attrs=None):
        if parent is not None and parent not in self.folder_parent:
            raise KeyError("unknown parent folder")
        self.folder_parent[name] = parent
        if parent is not None:
            self.folder_children.setdefault(parent, []).append(name)
        self.folder_children.setdefault(name, [])
        self.attr_values[name] = dict(attrs or {})

    def canonical_path(self, folder):
        """Ancestor walk by hand; cycle guard via seen set."""
        parts = []
        seen = set()
        cur = folder
        while cur is not None and cur not in seen:
            seen.add(cur)
            parts.append(cur)
            cur = self.folder_parent.get(cur)
        return "/".join(reversed(parts))

    def subtree_folders(self, root):
        """Explicit stack walk over the children adjacency dict."""
        out = []
        stack = [root]
        seen = set()
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            stack.extend(self.folder_children.get(cur, []))
        return sorted(out)

    def inherited_attribute(self, folder, attr):
        """Nearest ancestor (or self) carrying ``attr``; None otherwise."""
        seen = set()
        cur = folder
        while cur is not None and cur not in seen:
            seen.add(cur)
            val = self.attr_values.get(cur, {}).get(attr)
            if val is not None:
                return val
            cur = self.folder_parent.get(cur)
        return None

    def attach_chain(self, task=None, product=None, version=None,
                     folder=None):
        """Wire one link per call site; each hop validated."""
        if task is not None:
            if folder not in self.folder_parent:
                raise KeyError("unknown folder")
            self.task_folder[task] = folder
        elif product is not None:
            if product[1] not in self.task_folder:
                raise KeyError("unknown task")
            self.product_task[product[0]] = product[1]
        elif version is not None:
            if version[1] not in self.product_task:
                raise KeyError("unknown product")
            self.version_product[version[0]] = version[1]

    def versions_in_subtree(self, root):
        """Cross-type chain query: folders -> tasks -> products -> versions.

        Three hand-rolled hops over the link maps; results are a multiset.
        """
        folders = set(self.subtree_folders(root))
        tasks = [t for t, f in self.task_folder.items() if f in folders]
        products = [p for p, t in self.product_task.items() if t in tasks]
        versions = [v for v, p in self.version_product.items() if p in products]
        return sorted(versions)

    def entities_of_type(self, etype, root=None):
        """Mixed-entity listing filtered to one type, optionally scoped."""
        if etype == "folder":
            names = self.subtree_folders(root) if root else sorted(self.folder_parent)
        elif etype == "task":
            names = sorted(self.task_folder)
        elif etype == "product":
            names = sorted(self.product_task)
        else:
            names = sorted(self.version_product)
        return names
