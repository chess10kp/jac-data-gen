"""Monorepo build system, lifted to OSP.

Targets are nodes in a ChildOf hierarchy, source files are Source nodes
linked by Owns, and inter-target dependencies are DependsOn cross-links.
Walkers over typed edges replace the recursive ancestor ascent, the
reverse-dependency queue walk, and the dependency closure stack walk.
Cycle policy: the source tolerated dependency cycles via a visited guard;
the guard set here is domain logic and survives.
"""
node Target {
    has tid: str;
    has dirty: bool = False;
}

node Source {
    has path: str;
}

"""Component hierarchy: parent +>:ChildOf:+> child."""
edge ChildOf {}

"""Target owns a source file."""
edge Owns {}

"""Cross-link: target depends on another target."""
edge DependsOn {}

walker TouchCollector {
    """Collect owners of a touched file plus all transitive dependents,
    once-only per node (shared sources and dep cycles hit a node twice)."""
    has claimed: dict[str, bool] = {};
    has hits: set[str] = set();

    can step with Target entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.hits.add(here.tid);
        visit [here <-:DependsOn:<-];
        visit [here <-:Owns:<-];
    }
    can collect with Source entry {
        visit [here <-:Owns:<-];
    }
}

walker DirtyMarker {
    """Recursive ascent over ChildOf: mark target and ancestors dirty.
    Already-dirty nodes prune the ascent."""
    can step with Target entry {
        if here.dirty {
            disengage;
        }
        here.dirty = True;
        visit [here <-:ChildOf:<-] else { disengage; }
    }
}

"""Closure over forward DependsOn edges, once-only per node."""
walker DepClosure {
    has claimed: dict[str, bool] = {};

    can step with Target entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        visit [->:DependsOn:->];
    }
}

obj BuildGraph {
    """Compatibility facade. Target ids and file paths are the public API
    currency, so id -> node lookup maps live here as domain state."""
    has by_id: dict[str, Target] = {};
    has by_path: dict[str, Source] = {};

    def add_target(tid: str, parent: str | None = None) -> str {
        if tid in self.by_id {
            raise ValueError("duplicate target " + tid);
        }
        t := Target(tid=tid);
        if parent is not None {
            p = self.by_id[parent];
            p +>:ChildOf:+> t;
        }
        self.by_id[tid] = t;
        return tid;
    }

    def add_source(tid: str, path: str) {
        t = self.by_id[tid];
        src = self.by_path.get(path);
        if src is None {
            src = Source(path=path);
            self.by_path[path] = src;
        }
        t +>:Owns:+> src;
    }

    def declare_dep(tid: str, dep_tid: str) {
        if dep_tid == tid {
            raise ValueError("self dependency");
        }
        self.by_id[tid] +>:DependsOn:+> self.by_id[dep_tid];
    }

    """Two-phase touch: walkers collect affected targets, then dirty flags
    are applied outside the walks. Returns sorted ids of directly affected
    targets."""
    def touch(path: str) -> list[str] {
        src = self.by_path.get(path);
        if src is None {
            return [];
        }
        affected: set[str] = set();
        owners: list[Target] = [src <-:Owns:<-];
        for o in owners {
            w: TouchCollector = o spawn TouchCollector();
            affected |= w.hits;
        }
        for tid in affected {
            self.by_id[tid] spawn DirtyMarker();
        }
        return sorted(affected);
    }

    def dirty_targets() -> list[str] {
        return sorted(t.tid for t in self.by_id.values() if t.dirty);
    }

    def reset_dirty() {
        for t in self.by_id.values() {
            t.dirty = False;
        }
    }

    """Transitive dependency closure (cycle safe via guard set)."""
    def transitive_deps(tid: str) -> list[str] {
        result: set[str] = set();
        directs: list[Target] = [self.by_id[tid] ->:DependsOn:->];
        for d in directs {
            w = d spawn DepClosure();
            for tid in w.claimed.keys() {
                result.add(tid);
            }
            result.add(d.tid);
        }
        result.discard(tid);
        return sorted(result);
    }

    def path_to_root(tid: str) -> list[str] {
        chain: list[str] = [];
        cur: Target | None = self.by_id[tid];
        while cur is not None {
            chain.append(cur.tid);
            parents = [cur <-:ChildOf:<-];
            cur = parents[0] if len(parents) > 0 else None;
        }
        return chain;
    }
}
