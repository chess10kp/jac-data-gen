"""Plugin registry, lifted to OSP.

Groups form a Subgroup tree; plugins are nodes linked to groups by
MemberOf; dependencies are Requires cross-links. Uninstall follows the
two-phase protocol: a walker collects the doomed set over reverse Requires
edges (pruning pinned branches), the facade disconnects edges and retires
plugins outside the walk. Cycle policy: the source pruned revisits with a
visited set; skip-guards preserve that once-only behavior without aborting
sibling branches.
"""
node Group {
    has gid: str;
}

node Plugin {
    has pid: str;
    has pinned: bool = False;
    has dead: bool = False;
}

"""Group tree: parent +>:Subgroup:+> child."""
edge Subgroup {}

"""Plugin lives in a group."""
edge MemberOf {}

"""Dependency cross-link: dependent +>:Requires:+> dependency."""
edge Requires {}

walker DependentSweep {
    """BFS-equivalent sweep over incoming Requires edges collecting the
    transitive dependent set. Pinned branches are pruned; the origin is
    always removable when reached directly."""
    has origin: str;
    has force: bool;
    has claimed: dict[str, bool] = {};
    has doomed: set[str] = set();

    can step with Plugin entry {
        if here.pid in self.claimed {
            skip;
        }
        if here.pid != self.origin and here.pinned and not self.force {
            skip;  # prune the pinned branch
        }
        self.claimed[here.pid] = True;
        self.doomed.add(here.pid);
        visit [here <-:Requires:<-];
    }
}

walker GroupTally {
    """Recursive descent over Subgroup edges counting live member
    plugins. Guard set keeps shared groups once-only."""
    has count: int = 0;
    has claimed: dict[str, bool] = {};

    can step with Group entry {
        if here.gid in self.claimed {
            skip;
        }
        self.claimed[here.gid] = True;
        members = [here ->:MemberOf:->];
        for m in members {
            if not m.dead {
                self.count += 1;
            }
        }
        visit [->:Subgroup:->];
    }
}

obj PluginRegistry {
    """Compatibility facade. Group and plugin ids are public API
    currency; lookup maps are domain state."""
    has by_gid: dict[str, Group] = {};
    has by_pid: dict[str, Plugin] = {};

    def add_group(gid: str, parent: str | None = None) -> str {
        if gid in self.by_gid {
            raise ValueError("duplicate group " + gid);
        }
        g := Group(gid=gid);
        if parent is not None {
            p = self.by_gid[parent];
            p +>:Subgroup:+> g;
        }
        self.by_gid[gid] = g;
        return gid;
    }

    def add_plugin(pid: str, gid: str, pinned: bool = False) -> str {
        if pid in self.by_pid {
            raise ValueError("duplicate plugin " + pid);
        }
        pl := Plugin(pid=pid, pinned=pinned);
        self.by_gid[gid] +>:MemberOf:+> pl;
        self.by_pid[pid] = pl;
        return pid;
    }

    def require(pid: str, dep_pid: str) -> None {
        if dep_pid == pid {
            raise ValueError("self dependency");
        }
        existing = [self.by_pid[pid] ->:Requires:->];
        if self.by_pid[dep_pid] not in existing {
            self.by_pid[pid] +>:Requires:+> self.by_pid[dep_pid];
        }
    }

    def dependents_of(pid: str) -> list[str] {
        target = self.by_pid.get(pid);
        if target is None {
            return [];
        }
        users = [target <-:Requires:<-];
        return sorted(u.pid for u in users);
    }

    """Two-phase uninstall. Phase 1 sweeps dependents; phase 2 severs
    edges and retires plugins outside any walk."""
    def uninstall(pid: str, force: bool = False) -> list[str] {
        if pid not in self.by_pid {
            raise KeyError(pid);
        }
        if self.by_pid[pid].pinned and not force {
            return [];
        }
        w: DependentSweep = self.by_pid[pid] spawn DependentSweep(
            origin=pid, force=force
        );
        doomed: set[str] = w.doomed;
        for d in doomed {
            r = self.by_pid.pop(d);
            r.dead = True;
            reqs = [r ->:Requires:->];
            for t in reqs {
                r del ->:Requires:-> t;
            }
            users = [r <-:Requires:<-];
            for u in users {
                u del ->:Requires:-> r;
            }
            home = [r <-:MemberOf:<-];
            for g in home {
                g del ->:MemberOf:-> r;
            }
        }
        return sorted(doomed);
    }

    def group_load(gid: str) -> int {
        w: GroupTally = self.by_gid[gid] spawn GroupTally();
        return w.count;
    }
}
