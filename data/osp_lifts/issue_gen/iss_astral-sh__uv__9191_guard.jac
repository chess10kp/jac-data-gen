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

# hidden tests for astral-sh/uv#9191 lift
import from iss_astral-sh__uv__9191 {build_index, cascade_invalidate}

test "memo_ancestors_sorted_closure" {
    specs: list[tuple[str, int, int, str]] = [("app", 1, 1, "h1"), ("lib", 2, 2, "h2"), ("base", 3, 3, "h3")];
    reg = build_index(specs);
    reg.link("app", "lib");
    reg.link("lib", "base");
    c = FreshnessCache();
    anc = c.memo_ancestors(reg.get("app"));
    assert anc == ["base", "lib"];
}

test "memo_ancestors_unknown_root" {
    specs: list[tuple[str, int, int, str]] = [("solo", 1, 1, "h")];
    reg = build_index(specs);
    c = FreshnessCache();
    anc = c.memo_ancestors(reg.get("solo"));
    assert anc == [];
}

test "cycle_diamond_closure" {
    specs: list[tuple[str, int, int, str]] = [("a", 1, 1, "ha"), ("b", 2, 2, "hb"), ("c", 3, 3, "hc"), ("d", 4, 4, "hd")];
    reg = build_index(specs);
    reg.link("a", "b");
    reg.link("b", "d");
    reg.link("a", "c");
    reg.link("c", "d");
    reg.link("d", "a");
    r = cascade_invalidate(reg, "a");
    assert r == ["a", "b", "c", "d"];
}

test "cascade_invalidate_unknown_pid" {
    specs: list[tuple[str, int, int, str]] = [("x", 1, 1, "hx")];
    reg = build_index(specs);
    assert cascade_invalidate(reg, "missing") == [];
}

test "freshness_inode_drift" {
    specs: list[tuple[str, int, int, str]] = [("app", 1, 1, "h1"), ("lib", 2, 2, "h2")];
    reg = build_index(specs);
    reg.link("app", "lib");
    c = FreshnessCache();
    c.record(reg.get("app"));
    assert c.is_fresh(reg.get("app")) == True;
    rebuilt = Pkg(pid="app", ctime=999, inode=42, checksum="h1");
    assert c.is_fresh(rebuilt) == False;
}

test "link_unknown_nodes_false" {
    specs: list[tuple[str, int, int, str]] = [("x", 1, 1, "hx")];
    reg = build_index(specs);
    assert reg.link("x", "ghost") == False;
    assert reg.get("ghost") is None;
}
