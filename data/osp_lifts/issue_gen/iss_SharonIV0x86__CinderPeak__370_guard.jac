"""CinderPeak cycle detection lift — SharonIV0x86/CinderPeak#370."""

node V {
    has vid: str;
    has color: int = 0;
}

node Hub {
    has directed: bool = True;
    has verts: dict[str, V] = {};
}

edge Arc {}

walker DirCycleProbe {
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    can probe with V entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        print ["dfs_enter", here.vid];
        here.color = 1;
        nxt_list: list[V] = [];
        for nxt in [here ->:Arc:->][?:V] {
            if nxt.color == 1 {
                self.found = True;
                print ["directed_back", here.vid, nxt.vid];
            } elif nxt.color == 0 {
                nxt_list.append(nxt);
            }
        }
        if len(nxt_list) > 0 {
            visit :0: nxt_list;
        }
        here.color = 2;
    }
}

walker CycleDemo {
    can run with Hub entry {
        print ["demo", "start"];
        add_vertex(here, "1");
        add_vertex(here, "2");
        add_vertex(here, "3");
        add_edge(here, "1", "2");
        add_edge(here, "2", "3");
        add_edge(here, "3", "1");
        hc = has_cycle(here);
        print ["demo", "has_cycle", hc];
        disengage;
    }
}

def make_graph(directed: bool = True) -> Hub {
    gh = Hub(directed=directed);
    root ++> gh;
    return gh;
}

def add_vertex(h: Hub, vid: str) -> V {
    if vid in h.verts {
        return h.verts[vid];
    }
    nd = V(vid=vid);
    root ++> nd;
    h.verts[vid] = nd;
    return nd;
}

def add_edge(h: Hub, u: str, v: str) -> None {
    if u not in h.verts {
        return;
    }
    if v not in h.verts {
        return;
    }
    a = h.verts[u];
    b = h.verts[v];
    a +>:Arc:+> b;
    if not h.directed {
        b +>:Arc:+> a;
    }
}

def _uf_find(parent: dict[str, str], x: str) -> str {
    px = parent[x];
    if px != x {
        rp = _uf_find(parent, px);
        parent[x] = rp;
        return rp;
    }
    return x;
}

def has_cycle_directed(h: Hub) -> bool {
    keys: list[str] = sorted(h.verts.keys());
    for i in range(len(keys)) {
        h.verts[keys[i]].color = 0;
    }
    for i in range(len(keys)) {
        v = h.verts[keys[i]];
        if v.color == 0 {
            wk = v spawn DirCycleProbe(claimed={});
            print ["directed_probe", v.vid, wk.found];
            if wk.found {
                return True;
            }
        }
    }
    return False;
}

def has_cycle_undirected(h: Hub) -> bool {
    parent: dict[str, str] = {};
    keys: list[str] = sorted(h.verts.keys());
    for i in range(len(keys)) {
        parent[keys[i]] = keys[i];
    }
    seen: dict[str, bool] = {};
    for i in range(len(keys)) {
        u = h.verts[keys[i]];
        for nb in [u ->:Arc:->][?:V] {
            a: str = u.vid;
            b: str = nb.vid;
            if a < b {
                ek: str = a + "|" + b;
            } else {
                ek = b + "|" + a;
            }
            if ek in seen {
                continue;
            }
            seen[ek] = True;
            pu = _uf_find(parent, a);
            pv = _uf_find(parent, b);
            if pu == pv {
                print ["undirected_cycle", a, b];
                return True;
            }
            parent[pu] = pv;
        }
    }
    return False;
}

def has_cycle(h: Hub) -> bool {
    if h.directed {
        return has_cycle_directed(h);
    }
    return has_cycle_undirected(h);
}

with entry {
    seed = Hub(directed=True);
    root ++> seed;
    seed spawn CycleDemo;
}

test "directed_acyclic" {
    h = make_graph(directed=True);
    add_vertex(h, "a");
    add_vertex(h, "b");
    add_vertex(h, "c");
    add_edge(h, "a", "b");
    add_edge(h, "b", "c");
    assert (has_cycle(h) == False);;
    assert (has_cycle_directed(h) == False);;
}

test "directed_cycle" {
    h = make_graph(directed=True);
    add_vertex(h, "1");
    add_vertex(h, "2");
    add_vertex(h, "3");
    add_edge(h, "1", "2");
    add_edge(h, "2", "3");
    add_edge(h, "3", "1");
    assert (has_cycle_directed(h) == True);;
    assert (has_cycle(h) == True);;
}

test "undirected_acyclic" {
    h = make_graph(directed=False);
    add_vertex(h, "x");
    add_vertex(h, "y");
    add_vertex(h, "z");
    add_edge(h, "x", "y");
    add_edge(h, "y", "z");
    assert (has_cycle_undirected(h) == False);;
    assert (has_cycle(h) == False);;
}

test "undirected_cycle" {
    h = make_graph(directed=False);
    add_vertex(h, "p");
    add_vertex(h, "q");
    add_vertex(h, "r");
    add_edge(h, "p", "q");
    add_edge(h, "q", "r");
    add_edge(h, "p", "r");
    assert (has_cycle_undirected(h) == True);;
    assert (has_cycle(h) == True);;
}

test "missing_vertex_edge_noop" {
    h = make_graph(directed=True);
    add_vertex(h, "only");
    add_edge(h, "only", "ghost");
    add_edge(h, "ghost", "only");
    assert (has_cycle(h) == False);;
}

test "duplicate_vertex_returns_same" {
    h = make_graph(directed=True);
    v1 = add_vertex(h, "dup");
    v2 = add_vertex(h, "dup");
    assert (v1.vid == "dup");;
    assert (v2.vid == "dup");;
}
