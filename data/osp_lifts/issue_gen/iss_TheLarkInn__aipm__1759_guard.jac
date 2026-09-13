# TheLarkInn/aipm#1759 — Build Performance Report (cargo build timings, duplicate crates)
node BuildGraph { has gid: str = "root"; }
node Crate { has cid: str; has name: str; has ver: str; has duration: float; has start: float; }
edge Depends {}

walker Gather {
    has claimed: dict[str, bool] = {};
    has out: list[Crate] = [];
    can start with BuildGraph entry {
        for nxt in [here -->][?:Crate] { visit :0: [nxt]; }
        print("gather start");
    }
    can step with Crate entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.out.append(here);
        for nxt in [here ->:Depends:->][?:Crate] { visit :0: [nxt]; }
        print(here.cid);
    }
}

walker Reach {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Crate entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        for nxt in [here ->:Depends:->][?:Crate] { visit :0: [nxt]; }
        print(here.cid);
    }
}

walker Bootstrap {
    has dummy: int = 0;
    can boot with entry { print("bootstrap"); }
}

def create_graph() -> BuildGraph { g = BuildGraph(gid="root"); return g; }

def add_crate(graph: BuildGraph, cid: str, name: str, ver: str, duration: float, start: float) -> Crate {
    c = Crate(cid=cid, name=name, ver=ver, duration=duration, start=start);
    graph ++> c;
    return c;
}

def add_dependency(src: Crate, dst: Crate) { src +>:Depends:+> dst; }

def get_transitive_deps(graph: BuildGraph, cid: str) -> list[str] {
    w = graph spawn Gather(claimed={}, out=[]);
    tgt: Crate | None = None;
    for nd in w.out { if nd.cid == cid { tgt = nd; } }
    if tgt == None { return []; }
    # narrow optional before edge connect
    start: Crate = tgt as Crate;
    r = start spawn Reach(claimed={}, found=[]);
    res: list[str] = [];
    for x in r.found { if x != cid { res.append(x); } }
    return sorted(res);
}

def get_slowest_units(graph: BuildGraph, n: int) -> list[str] {
    w = graph spawn Gather(claimed={}, out=[]);
    copy: list[Crate] = [];
    for nd in w.out { copy.append(nd); }
    ordered: list[str] = [];
    while len(copy) > 0 {
        best: Crate = copy[0];
        for cand in copy { if cand.duration > best.duration { best = cand; } }
        ordered.append(best.cid);
        nxt: list[Crate] = [];
        for cand in copy { if cand.cid != best.cid { nxt.append(cand); } }
        copy = nxt;
    }
    out: list[str] = [];
    cnt: int = 0;
    for cid in ordered { if cnt < n { out.append(cid); cnt += 1; } }
    return out;
}

def find_duplicate_names(graph: BuildGraph) -> dict[str, list[str]] {
    w = graph spawn Gather(claimed={}, out=[]);
    tmp: dict[str, list[str]] = {};
    for nd in w.out {
        if nd.name in tmp {
            cur: list[str] = tmp[nd.name];
            already: bool = False;
            for v in cur { if v == nd.ver { already = True; } }
            if not already { cur.append(nd.ver); }
        } else {
            lst: list[str] = [];
            lst.append(nd.ver);
            tmp[nd.name] = lst;
        }
    }
    res: dict[str, list[str]] = {};
    for k in tmp {
        vals: list[str] = tmp[k];
        if len(vals) > 1 { res[k] = sorted(vals); }
    }
    return res;
}

def total_wall_time(graph: BuildGraph) -> float {
    w = graph spawn Gather(claimed={}, out=[]);
    best: float = 0.0;
    for nd in w.out {
        v: float = nd.start + nd.duration;
        if v > best { best = v; }
    }
    return best;
}

def has_path(graph: BuildGraph, src: str, dst: str) -> bool {
    deps: list[str] = get_transitive_deps(graph, src);
    for x in deps { if x == dst { return True; } }
    return False;
}

with entry { root spawn Bootstrap(dummy=0); }

test "diamond revisit transitive deps" {
    graph = create_graph();
    a = add_crate(graph, "a", "pkgA", "1.0.0", 10.0, 0.0);
    b = add_crate(graph, "b", "pkgB", "1.0.0", 5.0, 1.0);
    c = add_crate(graph, "c", "pkgC", "1.0.0", 6.0, 1.0);
    d = add_crate(graph, "d", "pkgD", "1.0.0", 2.0, 2.0);
    add_dependency(a, b);
    add_dependency(a, c);
    add_dependency(b, d);
    add_dependency(c, d);
    deps = get_transitive_deps(graph, "a");
    assert sorted(deps) == ["b", "c", "d"];
    assert has_path(graph, "a", "d");
    assert not has_path(graph, "b", "c");
}

test "unknown id tolerance" {
    graph = create_graph();
    a = add_crate(graph, "a", "pkgA", "1.0.0", 1.0, 0.0);
    deps = get_transitive_deps(graph, "missing");
    assert deps == [];
    assert not has_path(graph, "missing", "a");
    assert not has_path(graph, "a", "missing");
    dup = find_duplicate_names(graph);
    assert len(dup) == 0;
    wt = total_wall_time(graph);
    assert wt == 1.0;
}

test "duplicate crate versions grouped" {
    graph = create_graph();
    add_crate(graph, "c1", "bitflags", "1.3.2", 1.0, 0.0);
    add_crate(graph, "c2", "bitflags", "2.11.0", 1.2, 0.1);
    add_crate(graph, "c3", "heck", "0.4.1", 0.5, 0.2);
    add_crate(graph, "c4", "heck", "0.5.0", 0.6, 0.3);
    add_crate(graph, "c5", "tower", "0.4.13", 2.0, 0.4);
    dup = find_duplicate_names(graph);
    assert "bitflags" in dup;
    assert sorted(dup["bitflags"]) == ["1.3.2", "2.11.0"];
    assert sorted(dup["heck"]) == ["0.4.1", "0.5.0"];
    assert "tower" not in dup;
}

test "slowest units and cycle safe" {
    graph = create_graph();
    a = add_crate(graph, "aws", "aws-lc-sys", "0.40.0", 93.86, 16.06);
    b = add_crate(graph, "git", "libgit2-sys", "0.17.0", 71.69, 120.0);
    c = add_crate(graph, "syn", "syn", "2.0.117", 27.02, 4.27);
    add_dependency(a, b);
    add_dependency(b, c);
    add_dependency(c, a);
    slowest = get_slowest_units(graph, 2);
    assert slowest[0] == "aws";
    assert slowest[1] == "git";
    deps = get_transitive_deps(graph, "aws");
    assert sorted(deps) == ["git", "syn"];
    wt = total_wall_time(graph);
    assert wt == 191.69;
}
