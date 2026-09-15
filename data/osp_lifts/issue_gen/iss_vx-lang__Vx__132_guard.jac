"""vx-lang/Vx#132 — multi-hop transfer semantic verification without pinned-default re-eval loops."""

node MemorySpace {
    has cid: str;
    has name: str;
    has pinned_parent: str;
}

edge Hop {}

obj TopoHandle {
    has graph_root: MemorySpace;
}

walker SpaceFinder {
    has want: str;
    has claimed: dict[str, bool] = {};
    has hit: MemorySpace | None = None;

    can seek with MemorySpace entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("seek ", here.cid);
        if here.cid == self.want {
            self.hit = here;
            disengage;
        }
        kids: list[MemorySpace] = [here ->:Hop:->][?:MemorySpace];
        visit :0: kids;
        if not kids { disengage; }
    }
}

walker BfsPath {
    has dst: str;
    has start_cid: str;
    has claimed: dict[str, bool] = {};
    has prev: dict[str, str] = {};
    has found: list[str] = [];

    can bfs with MemorySpace entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("bfs ", here.cid);
        if here.cid == self.dst {
            self.found = build_path(self.prev, here.cid, self.start_cid);
            disengage;
        }
        kids: list[MemorySpace] = [here ->:Hop:->][?:MemorySpace];
        for kid in kids {
            if kid.cid not in self.prev {
                self.prev[kid.cid] = here.cid;
            }
            visit kid;
        }
        if not kids { disengage; }
    }
}

def build_path(prev: dict[str, str], end: str, start: str) -> list[str] {
    chain: list[str] = [];
    cur: str = end;
    while True {
        chain.append(cur);
        if cur == start { break; }
        if cur not in prev { return []; }
        cur = prev[cur];
    }
    out: list[str] = [];
    i: int = len(chain) - 1;
    while i >= 0 {
        out.append(chain[i]);
        i -= 1;
    }
    return out;
}

def find_space(graph_root: MemorySpace, cid: str) -> MemorySpace | None {
    f = graph_root spawn SpaceFinder(want=cid);
    return f.hit;
}

def make_topology() -> TopoHandle {
    npu = MemorySpace(cid="npu_hbm", name="NPUHBM", pinned_parent="npu0");
    nic = MemorySpace(cid="nic_ram", name="NicRam", pinned_parent="npu0");
    remote = MemorySpace(cid="remote_hbm", name="RemoteHbm", pinned_parent="npu0");
    root ++> npu;
    npu +>:Hop:+> nic;
    nic +>:Hop:+> remote;
    return TopoHandle(graph_root=npu);
}

def shortest_memory_path(topo: TopoHandle, src: str, dst: str) -> list[str] {
    src_node = find_space(topo.graph_root, src);
    if not src_node { return []; }
    w = src_node spawn BfsPath(dst=dst, start_cid=src);
    return w.found;
}

def default_pinned_space(topo: TopoHandle, space_id: str) -> str {
    nd = find_space(topo.graph_root, space_id);
    if not nd { return ""; }
    if nd.pinned_parent == "npu0" { return "npu_hbm"; }
    return nd.cid;
}

def build_nested_chain(tensor: str, hops: list[str]) -> dict {
    cur: dict = {"tensor": tensor, "space": hops[0], "inner": None};
    i: int = 1;
    while i < len(hops) {
        cur = {"tensor": tensor, "space": hops[i], "inner": cur};
        i += 1;
    }
    return cur;
}

def rewrite_implicit_transfer(topo: TopoHandle, tensor: str, target: str) -> dict {
    origin: str = "npu_hbm";
    full: list[str] = shortest_memory_path(topo, origin, target);
    if not full { return {"tensor": tensor, "space": target, "inner": None}; }
    hops: list[str] = [];
    j: int = 1;
    while j < len(full) {
        hops.append(full[j]);
        j += 1;
    }
    if not hops { return {"tensor": tensor, "space": target, "inner": None}; }
    return build_nested_chain(tensor, hops);
}

def verify_transfer_space(topo: TopoHandle, expr: dict) -> str {
    inner_val = expr["inner"];
    if inner_val {
        inner_expr = inner_val as dict;
        verify_transfer_space(topo, inner_expr);
        hop_space: str = expr["space"] as str;
        return hop_space;
    }
    return expr["space"] as str;
}

test "diamond_revisit_claimed_skip" {
    a = MemorySpace(cid="da", name="DA", pinned_parent="");
    b = MemorySpace(cid="db", name="DB", pinned_parent="");
    c = MemorySpace(cid="dc", name="DC", pinned_parent="");
    d = MemorySpace(cid="dd", name="DD", pinned_parent="");
    root ++> a;
    a +>:Hop:+> b;
    a +>:Hop:+> c;
    b +>:Hop:+> d;
    c +>:Hop:+> d;
    topo = TopoHandle(graph_root=a);
    p = shortest_memory_path(topo, "da", "dd");
    assert len(p) == 3;
    assert p[0] == "da";
    assert p[2] == "dd";
}

test "unknown_cid_yields_none_and_empty_path" {
    topo = make_topology();
    nd = find_space(topo.graph_root, "missing");
    assert not nd;
    p = shortest_memory_path(topo, "missing", "remote_hbm");
    assert p == [];
}

test "pinned_default_collapses_distinct_spaces" {
    topo = make_topology();
    assert default_pinned_space(topo, "nic_ram") == "npu_hbm";
    assert default_pinned_space(topo, "remote_hbm") == "npu_hbm";
    assert default_pinned_space(topo, "missing") == "";
}

test "rewrite_builds_explicit_multi_hop_chain" {
    topo = make_topology();
    expr = rewrite_implicit_transfer(topo, "tensor0", "remote_hbm");
    assert expr["space"] == "remote_hbm";
    inner = expr["inner"] as dict;
    assert inner["space"] == "nic_ram";
    assert inner["inner"] is None;
}

test "verify_uses_expr_space_not_pinned_default" {
    topo = make_topology();
    expr = rewrite_implicit_transfer(topo, "tensor0", "remote_hbm");
    inner = expr["inner"] as dict;
    got = verify_transfer_space(topo, inner);
    assert got == "nic_ram";
    assert got != default_pinned_space(topo, "nic_ram");
    assert verify_transfer_space(topo, expr) == "remote_hbm";
}
