# Lift of astral-sh/uv#9191: cache invalidation on local dependencies in docker.
# Python original hand-rolled adjacency dicts + memoized ancestor closure +
# cascade invalidation sweep. Here: native OSP graph with node Pkg, edge Dep.

node Pkg {
    has pid: str;
    has ctime: int = 0;
    has inode: int = 0;
    has checksum: str = "";
}

edge Dep {
    has requires_editable: bool = True;
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];
    has origin_pid: str = "";

    can step with Pkg entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        if here.pid != self.origin_pid { self.acc.append(here.pid); }
        visit [here ->:Dep:->];
    }
}

obj PkgRegistry {
    has nodes: dict[str, Pkg];

    def init {
        self.nodes = {};
    }

    def add(pid: str, ctime: int, inode: int, checksum: str) -> Pkg {
        p = Pkg(pid=pid, ctime=ctime, inode=inode, checksum=checksum);
        self.nodes[pid] = p;
        root ++> p;
        return p;
    }

    def link(src: str, dst: str) -> bool {
        if (src not in self.nodes) or (dst not in self.nodes) { return False; }
        self.nodes[src] +>:Dep:+> self.nodes[dst];
        return True;
    }

    def get(pid: str) -> Pkg | None {
        if pid in self.nodes { return self.nodes[pid]; }
        return None;
    }
}

def build_index(specs: list[tuple[str, int, int, str]]) -> PkgRegistry {
    reg = PkgRegistry();
    for s in specs {
        reg.add(s[0], s[1], s[2], s[3]);
    }
    return reg;
}

def cascade_invalidate(reg: PkgRegistry, pid: str) -> list[str] {
    # Collect first (claim-map walk), no mutation during walk.
    start = reg.get(pid);
    if start is None { return []; }
    wk = start spawn AncestorWalk(claimed={}, acc=[], origin_pid=pid);
    return sorted(wk.acc);
}
