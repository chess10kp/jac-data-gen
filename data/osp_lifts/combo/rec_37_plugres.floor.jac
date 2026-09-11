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
class Group {
    def init(self: Group, gid: Any, parent: Any = None) -> object {
        self.gid = gid;
        self.parent = parent;
        self.children = [];
    }
}
class Plugin {
    def init(self: Plugin, pid: Any, gid: Any, pinned: Any = False) -> object {
        self.pid = pid;
        self.gid = gid;
        self.pinned = pinned;
        self.dead = False;
    }
}
class PluginRegistry {
    def init(self: PluginRegistry) -> object {
        self.groups = {};
        self.plugins = {};
        self.depends = {};
    }
    def add_group(self: PluginRegistry, gid: Any, parent: Any = None) -> object {
        if (gid in self.groups) {
            raise ValueError("duplicate group");
        }
        p = self.groups[parent] if (parent is not None) else None;
        g = Group(gid, p);
        if (p is not None) {
            p.children.append(g);
        }
        self.groups[gid] = g;
        return gid;
    }
    def add_plugin(
        self: PluginRegistry, pid: Any, gid: Any, pinned: Any = False
    ) -> object {
        if (pid in self.plugins) {
            raise ValueError("duplicate plugin");
        }
        if (gid not in self.groups) {
            raise KeyError(gid);
        }
        self.plugins[pid] = Plugin(pid, gid, pinned);
    }
    def require(self: PluginRegistry, pid: Any, dep_pid: Any) -> object {
        if (dep_pid == pid) {
            raise ValueError("self dependency");
        }
        self.depends.setdefault(pid, `set()).add(dep_pid);
    }
    def _group_subtree_ids(self: PluginRegistry, gid: Any) -> object {
        out = [];
        stack = [gid];
        while stack {
            cur = stack.pop();
            out.append(cur);
            kids = self.groups[cur].children as list;
            for c in kids {
                cg = c as Group;
                stack.append(cg.gid);
            }
        }
        return out;
    }
    """Number of live plugins in the group subtree."""
    def group_load(self: PluginRegistry, gid: Any) -> object {
        gids = `set(self._group_subtree_ids(gid));
        return sum(
            1
            for p in self.plugins.values()
            if (not p.dead and (p.gid in gids))
        );
    }
    """Direct dependents of pid, sorted."""
    def dependents_of(self: PluginRegistry, pid: Any) -> object {
        return sorted(
            src
            for (src, ds) in self.depends.items()
            if (pid in ds)
        );
    }
    """Cascade-uninstall transitive hard dependents. Pinned plugins
        are pruned from the removal set unless force is set. Returns the
        sorted list of removed plugin ids."""
    def uninstall(self: PluginRegistry, pid: Any, force: Any = False) -> object {
        if (pid not in self.plugins) {
            raise KeyError(pid);
        }
        if (self.plugins[pid].pinned and not force) {
            return [];
        }
        doomed = `set();
        q = [pid];
        while q {
            cur = q.pop(0);
            if (cur in doomed) {
                continue;
            }
            if ((cur != pid) and self.plugins[cur].pinned and not force) {
                continue;
            }
            doomed.add(cur);
            q.extend(
                src
                for (src, ds) in self.depends.items()
                if (cur in ds)
            );
        }
        for d in doomed {
            p = self.plugins.pop(d);
            p.dead = True;
        }
        for src in `list(self.depends) {
            if (src in doomed) {
                delete(self.depends[src],);
            } else {
                ds2 = self.depends[src] as set;
                self.depends[src] = ds2 - doomed;
            }
        }
        return sorted(doomed);
    }
}

