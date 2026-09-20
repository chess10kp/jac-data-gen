"""Parallel cloud session coordination — tree-sitter-perl/perl-lsp#120."""

node Module {
    has mid: str;
    has depth_gate: int = 0;
}

node Seam {
    has sid: str;
}

edge Depends {}
edge Invalidates {}

walker BuildOrder {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can visit_mod with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.order.append(here.mid);
        print(here.mid);
        kids: list[Module] = [here ->:Depends:->][?:Module];
        mids: list[str] = [];
        for k in kids {
            mids.append(k.mid);
        }
        mids = sorted(mids);
        for mid in mids {
            for k in kids {
                if k.mid == mid {
                    visit :0: [k];
                }
            }
        }
    }
}

walker CascadeInvalidate {
    has claimed: dict[str, bool] = {};
    has invalidated: list[str] = [];

    can visit_seam with Seam entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.invalidated.append(here.sid);
        print(here.sid);
        mods: list[Module] = [here ->:Invalidates:->][?:Module];
        for m in mods {
            visit [m];
        }
    }

    can visit_mod with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.invalidated.append(here.mid);
        print(here.mid);
        deps: list[Module] = [here ->:Depends:->][?:Module];
        dmids: list[str] = [];
        for d in deps {
            dmids.append(d.mid);
        }
        dmids = sorted(dmids);
        for dmid in dmids {
            for d in deps {
                if d.mid == dmid {
                    visit [d];
                }
            }
        }
    }
}

def make_module(mid: str, depth_gate: int) -> Module {
    return Module(mid=mid, depth_gate=depth_gate);
}

def connect_dep(parent: Module, child: Module) {
    parent +>:Depends:+> child;
}

def build_index_modules(edges: list[list[str]], depths: dict[str, int] | None) -> Module | None {
    nodes: dict[str, Module] = {};
    depth_map: dict[str, int] = {};
    if depths is not None {
        depth_map = depths;
    }
    for pair in edges {
        a: str = pair[0];
        b: str = pair[1];
        if a not in nodes {
            dg: int = 0;
            if a in depth_map { dg = depth_map[a]; }
            nodes[a] = make_module(a, dg);
        }
        if b not in nodes {
            dg2: int = 0;
            if b in depth_map { dg2 = depth_map[b]; }
            nodes[b] = make_module(b, dg2);
        }
        connect_dep(nodes[a], nodes[b]);
    }
    if len(edges) == 0 {
        return None;
    }
    graph_root: Module = nodes[edges[0][0]];
    root ++> graph_root;
    return graph_root;
}

def iterative_build_order(edges: list[list[str]], depths: dict[str, int] | None) -> list[str] {
    graph_root = build_index_modules(edges, depths);
    if graph_root is None {
        return [];
    }
    w = graph_root spawn BuildOrder(claimed={});
    return w.order;
}

def cascade_invalidate(seam_id: str, invalidates: list[list[str]], deps: list[list[str]]) -> list[str] {
    seams: dict[str, Seam] = {};
    modules: dict[str, Module] = {};
    s = Seam(sid=seam_id);
    seams[seam_id] = s;
    root ++> s;
    for pair in invalidates {
        sid: str = pair[0];
        mid: str = pair[1];
        if sid not in seams {
            seams[sid] = Seam(sid=sid);
            root ++> seams[sid];
        }
        if mid not in modules {
            modules[mid] = make_module(mid, 0);
            root ++> modules[mid];
        }
        seams[sid] +>:Invalidates:+> modules[mid];
    }
    for pair in deps {
        a: str = pair[0];
        b: str = pair[1];
        if a not in modules {
            modules[a] = make_module(a, 0);
            root ++> modules[a];
        }
        if b not in modules {
            modules[b] = make_module(b, 0);
            root ++> modules[b];
        }
        modules[a] +>:Depends:+> modules[b];
    }
    w = s spawn CascadeInvalidate(claimed={});
    return sorted(w.invalidated);
}

def session_task(letter: str) -> str {
    board: dict[str, str] = {};
    board["A"] = "narrow-seam-cache-indexcore";
    board["B"] = "iterative-builder-walk";
    board["C"] = "inc-single-provider-tier";
    if letter in board {
        return board[letter];
    }
    return "";
}

def seam_conflicts(ownership: dict[str, list[str]], seam: str) -> list[str] {
    owners: list[str] = [];
    keys: list[str] = sorted(ownership);
    for k in keys {
        files: list[str] = ownership[k];
        for f in files {
            if f == seam {
                owners.append(k);
            }
        }
    }
    return sorted(owners);
}

def scale_baseline_ok(unit: int, gold: int, fail: int) -> bool {
    return unit == 1511 and gold == 491 and fail == 0;
}

with entry {
    demo_edges: list[list[str]] = [];
    demo_edges.append(["IndexCore", "Builder"]);
    demo_edges.append(["Builder", "CST"]);
    gr = build_index_modules(demo_edges, None);
    if gr is not None {
        gr spawn BuildOrder(claimed={});
    }
    print(session_task("B"));
}

test "build_order_linear" {
    edges: list[list[str]] = [];
    edges.append(["IndexCore", "Builder"]);
    edges.append(["Builder", "CST"]);
    got = iterative_build_order(edges, None);
    assert got == ["IndexCore", "Builder", "CST"];
}

test "build_order_empty" {
    got = iterative_build_order([], None);
    assert got == [];
}

test "build_order_diamond_adversarial" {
    edges: list[list[str]] = [];
    edges.append(["A", "B"]);
    edges.append(["A", "C"]);
    edges.append(["B", "D"]);
    edges.append(["C", "D"]);
    got = iterative_build_order(edges, None);
    assert got == ["A", "B", "D", "C"];
}

test "cascade_invalidate_closure" {
    inv: list[list[str]] = [];
    inv.append(["s1", "M1"]);
    deps: list[list[str]] = [];
    deps.append(["M1", "M2"]);
    got = cascade_invalidate("s1", inv, deps);
    assert got == ["M1", "M2", "s1"];
}

test "session_task_and_seam_conflicts" {
    assert session_task("B") == "iterative-builder-walk";
    ownership: dict[str, list[str]] = {};
    ownership["a"] = ["foo.jac"];
    ownership["b"] = ["foo.jac", "bar.jac"];
    assert seam_conflicts(ownership, "foo.jac") == ["a", "b"];
}

test "scale_baseline_ok" {
    assert scale_baseline_ok(1511, 491, 0) == True;
    assert scale_baseline_ok(1, 2, 3) == False;
}
