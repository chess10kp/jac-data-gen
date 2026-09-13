node Crate {
    has cid: str;
    has name: str;
    has version: str;
    has duration: float;
    has kind: str;
}
node BuildRoot {
    has rid: str;
}
edge Depends {}

walker CollectReachable {
    has claimed: dict[str, bool] = {};
    has found: list[Crate] = [];
    can collect with Crate entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here);
        for nxt in [here ->:Depends:->][?:Crate] {
            visit [nxt];
        }
        print("visited " + here.cid);
    }
}

walker CollectFromRoot {
    has claimed: dict[str, bool] = {};
    has found: list[Crate] = [];
    can step_root with BuildRoot entry {
        for nxt in [here ->:Depends:->][?:Crate] {
            visit [nxt];
        }
        print("root visited " + here.rid);
    }
    can step_crate with Crate entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here);
        for nxt in [here ->:Depends:->][?:Crate] {
            visit [nxt];
        }
        print("visited " + here.cid);
    }
}

def create_build_graph(rid: str) -> BuildRoot {
    g = BuildRoot(rid=rid);
    return g;
}

def register_crate(graph_root: BuildRoot, cid: str, name: str, version: str, duration: float, kind: str) -> Crate {
    nd = Crate(cid=cid, name=name, version=version, duration=duration, kind=kind);
    graph_root +>:Depends:+> nd;
    return nd;
}

def add_depends(src: Crate, dst: Crate) {
    src +>:Depends:+> dst;
}

def transitive_closure(start: Crate) -> list[str] {
    w = start spawn CollectReachable(claimed={}, found=[]);
    ids: list[str] = [];
    for c in w.found {
        ids.append(c.cid);
    }
    return sorted(ids);
}

def transitive_closure_by_id(graph_root: BuildRoot, cid: str) -> list[str] {
    w = graph_root spawn CollectFromRoot(claimed={}, found=[]);
    target: Crate | None = None;
    for c in w.found {
        if c.cid == cid {
            target = c;
        }
    }
    if target is None {
        return [];
    }
    t: Crate = target;
    return transitive_closure(t);
}

def slowest_units(graph_root: BuildRoot, top_n: int) -> list[str] {
    w = graph_root spawn CollectFromRoot(claimed={}, found=[]);
    remaining: list[Crate] = [];
    for c in w.found {
        remaining.append(c);
    }
    result: list[str] = [];
    count: int = 0;
    if top_n > len(remaining) {
        count = len(remaining);
    } else {
        count = top_n;
    }
    for _ in range(count) {
        best: Crate | None = None;
        best_idx: int = 0;
        idx: int = 0;
        for c in remaining {
            if best is None {
                best = c;
                best_idx = idx;
            } else {
                bv: Crate = best;
                if c.duration > bv.duration {
                    best = c;
                    best_idx = idx;
                }
            }
            idx += 1;
        }
        if best is not None {
            b: Crate = best;
            result.append(b.cid);
            nxt: list[Crate] = [];
            j: int = 0;
            for c2 in remaining {
                if j != best_idx {
                    nxt.append(c2);
                }
                j += 1;
            }
            remaining = nxt;
        }
    }
    return result;
}

with entry {
    demo = BuildRoot(rid="demo");
    root ++> demo;
    w = demo spawn CollectFromRoot(claimed={}, found=[]);
    print("demo deps " + str(len(w.found)));
}

test "diamond adversarial revisit order" {
    g = create_build_graph(rid="g_diamond");
    a = register_crate(g, cid="a", name="a", version="1.0", duration=1.0, kind="lib");
    b = register_crate(g, cid="b", name="b", version="1.0", duration=2.0, kind="lib");
    c = register_crate(g, cid="c", name="c", version="1.0", duration=3.0, kind="lib");
    d = register_crate(g, cid="d", name="d", version="1.0", duration=4.0, kind="lib");
    # diamond a -> b, a -> c, b -> d, c -> d
    # insert c->d before b->d to force revisit of d before b path completes
    add_depends(a, b);
    add_depends(a, c);
    add_depends(c, d);
    add_depends(b, d);
    got = transitive_closure(a);
    assert got == ["a", "b", "c", "d"];
    got2 = transitive_closure_by_id(g, "a");
    assert got2 == ["a", "b", "c", "d"];
}

test "cycle does not truncate closure" {
    g = create_build_graph(rid="g_cycle");
    x = register_crate(g, cid="x", name="x", version="1.0", duration=5.0, kind="lib");
    y = register_crate(g, cid="y", name="y", version="1.0", duration=6.0, kind="lib");
    z = register_crate(g, cid="z", name="z", version="1.0", duration=7.0, kind="lib");
    w = register_crate(g, cid="w", name="w", version="1.0", duration=1.0, kind="lib");
    add_depends(x, y);
    add_depends(y, z);
    add_depends(z, x);
    add_depends(z, w);
    got = transitive_closure(x);
    assert got == ["w", "x", "y", "z"];
}

test "unknown id tolerance returns empty" {
    g = create_build_graph(rid="g_unknown");
    a = register_crate(g, cid="a", name="a", version="1.0", duration=10.0, kind="lib");
    got = transitive_closure_by_id(g, "no_such_crate");
    assert got == [];
    got2 = transitive_closure_by_id(g, "a");
    assert got2 == ["a"];
    empty = create_build_graph(rid="empty");
    got3 = transitive_closure_by_id(empty, "any");
    assert got3 == [];
}

test "slowest units ordering and top_n edge cases" {
    g = create_build_graph(rid="g_slow");
    register_crate(g, cid="aws-lc-sys", name="aws-lc-sys", version="0.40.0", duration=59.7, kind="build");
    register_crate(g, cid="libgit2-sys", name="libgit2-sys", version="0.17.0", duration=50.4, kind="build");
    register_crate(g, cid="syn", name="syn", version="2.0.117", duration=16.3, kind="proc-macro");
    register_crate(g, cid="rustls", name="rustls", version="0.23.37", duration=14.5, kind="lib");
    register_crate(g, cid="jsonschema", name="jsonschema", version="0.46.4", duration=13.6, kind="lib");
    got2 = slowest_units(g, 2);
    assert got2 == ["aws-lc-sys", "libgit2-sys"];
    got_all = slowest_units(g, 10);
    assert got_all == ["aws-lc-sys", "libgit2-sys", "syn", "rustls", "jsonschema"];
    got0 = slowest_units(g, 0);
    assert got0 == [];
}

test "isolated node and empty graph" {
    g = create_build_graph(rid="g_iso");
    lone = register_crate(g, cid="lone", name="lone", version="1.0", duration=2.0, kind="lib");
    got = transitive_closure(lone);
    assert got == ["lone"];
    empty = create_build_graph(rid="g_empty2");
    got2 = slowest_units(empty, 3);
    assert got2 == [];
}
