"""Plugin registry with dependency-aware uninstall.

Plugins are organized into nested category groups and declare dependencies
on other plugins. Uninstalling a plugin must uninstall every hard dependent
transitively, but pinned plugins are never removed: their branch of the
dependent graph is pruned. Group member counts are maintained up the group
tree after each removal.

Hand-rolled machinery:
- parent/children pointers over the group tree (C1)
- reverse-dependency adjacency dict walked as a BFS frontier (C2/C5)
"""


class Group:
    def __init__(self, gid, parent=None):
        self.gid = gid
        self.parent = parent
        self.children = []


class Plugin:
    def __init__(self, pid, gid, pinned=False):
        self.pid = pid
        self.gid = gid
        self.pinned = pinned
        self.dead = False


class PluginRegistry:
    def __init__(self):
        self.groups = {}    # gid -> Group
        self.plugins = {}   # pid -> Plugin
        self.depends = {}   # pid -> set of dependency pids

    def add_group(self, gid, parent=None):
        if gid in self.groups:
            raise ValueError("duplicate group " + gid)
        p = self.groups[parent] if parent is not None else None
        g = Group(gid, p)
        if p is not None:
            p.children.append(g)
        self.groups[gid] = g
        return gid

    def add_plugin(self, pid, gid, pinned=False):
        if pid in self.plugins:
            raise ValueError("duplicate plugin " + pid)
        if gid not in self.groups:
            raise KeyError(gid)
        self.plugins[pid] = Plugin(pid, gid, pinned)

    def require(self, pid, dep_pid):
        if dep_pid == pid:
            raise ValueError("self dependency")
        self.depends.setdefault(pid, set()).add(dep_pid)

    def _group_subtree_ids(self, gid):
        out = []
        stack = [gid]
        while stack:
            cur = stack.pop()
            out.append(cur)
            stack.extend(c.gid for c in self.groups[cur].children)
        return out

    def group_load(self, gid):
        """Number of live plugins in the group subtree."""
        gids = set(self._group_subtree_ids(gid))
        return sum(1 for p in self.plugins.values()
                   if not p.dead and p.gid in gids)

    def dependents_of(self, pid):
        """Direct dependents of pid, sorted."""
        return sorted(src for src, ds in self.depends.items() if pid in ds)

    def uninstall(self, pid, force=False):
        """Cascade-uninstall transitive hard dependents. Pinned plugins
        are pruned from the removal set unless force is set. Returns the
        sorted list of removed plugin ids."""
        if pid not in self.plugins:
            raise KeyError(pid)
        if self.plugins[pid].pinned and not force:
            return []
        doomed = set()
        q = [pid]
        while q:
            cur = q.pop(0)
            if cur in doomed:
                continue
            if cur != pid and self.plugins[cur].pinned and not force:
                continue  # prune the pinned branch, keep its dependents
            doomed.add(cur)
            q.extend(src for src, ds in self.depends.items() if cur in ds)
        for d in doomed:
            p = self.plugins.pop(d)
            p.dead = True
        for src in list(self.depends):
            if src in doomed:
                del self.depends[src]
            else:
                self.depends[src] -= doomed
        return sorted(doomed)
