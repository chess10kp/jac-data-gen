"""Monorepo build system.

Build targets form a component hierarchy (each target has a parent target),
own source files, and declare dependencies on other targets. Touching a
source file dirties every target that owns it, every transitive dependent,
and all ancestors of each affected target (a change to a submodule invalidates
its parents' artifacts).

Hand-rolled machinery:
- parent/children pointers with recursive ancestor ascent (C1)
- file->targets index and target->deps adjacency with queue/stack walks (C2)
"""
class Target {
    def init(self: Target, tid: Any, parent: Any = None) -> object {
        self.tid = tid;
        self.parent = parent;
        self.children = [];
        self.sources = [];
        self.dirty = False;
    }
}
class BuildGraph {
    def init(self: BuildGraph) -> object {
        self.targets = {};
        self.file_index = {};
        self.deps = {};
    }
    def add_target(self: BuildGraph, tid: Any, parent: Any = None) -> object {
        if (tid in self.targets) {
            raise ValueError("duplicate target");
        }
        p = self.targets[parent] if (parent is not None) else None;
        t = Target(tid, p);
        if (p is not None) {
            p.children.append(t);
        }
        self.targets[tid] = t;
        return tid;
    }
    def add_source(self: BuildGraph, tid: Any, path: Any) -> object {
        t = self.targets[tid];
        t.sources.append(path);
        self.file_index.setdefault(path, []).append(tid);
    }
    def declare_dep(self: BuildGraph, tid: Any, dep_tid: Any) -> object {
        if (dep_tid == tid) {
            raise ValueError("self dependency");
        }
        self.deps.setdefault(tid, `set()).add(dep_tid);
    }
    """Recursive ascent: dirty a target and all of its ancestors."""
    def _mark_up(self: BuildGraph, t: Target) -> object {
        if t.dirty {
            return;
        }
        t.dirty = True;
        if (t.parent is not None) {
            self._mark_up(t.parent as Target);
        }
    }
    """Mark owners of path, their transitive dependents, and all
        ancestors dirty. Returns sorted ids of directly affected targets."""
    def touch(self: BuildGraph, path: Any) -> object {
        if (path not in self.file_index) {
            return [];
        }
        frontier = `list(self.file_index[path]);
        seeds = [];
        seen = `set();
        while frontier {
            tid = frontier.pop(0);
            if (tid in seen) {
                continue;
            }
            seen.add(tid);
            seeds.append(tid);
            for (other, ds) in self.deps.items() {
                if (tid in ds) {
                    frontier.append(other);
                }
            }
        }
        for tid in seeds {
            self._mark_up(self.targets[tid] as Target);
        }
        return sorted(seeds);
    }

    def dirty_targets(self: BuildGraph) -> object {
        return sorted(
            t.tid
            for t in self.targets.values()
            if t.dirty
        );
    }
    def reset_dirty(self: BuildGraph) -> object {
        for t in self.targets.values() {
            t.dirty = False;
        }
    }
    """Stack walk over the dependency adjacency (cycle safe)."""
    def transitive_deps(self: BuildGraph, tid: Any) -> object {
        seen = `set();
        stack = `list(self.deps.get(tid, []));
        while stack {
            d = stack.pop();
            if ((d in seen) or (d == tid)) {
                continue;
            }
            seen.add(d);
            stack.extend(self.deps.get(d, []));
        }
        return sorted(seen);
    }
    """Ancestor chain from tid up to the root target, inclusive."""
    def path_to_root(self: BuildGraph, tid: Any) -> object {
        chain = [];
        t = self.targets[tid];
        while (t is not None) {
            chain.append(t.tid);
            t = t.parent;
        }
        return chain;
    }
}

