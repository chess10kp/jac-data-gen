node Comp {
    has cid: str;
    has size: int = 0;
    has is_used: bool = True;
}
edge Depends {}
edge Owns {}
node GraphRoot {
    has name: str;
}
walker CollectTransitive {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can collect with Comp entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.out.append(here.cid);
        for nxt in [here ->:Depends:->][?:Comp] {
            visit :0: [nxt];
        }
        print(here.cid);
    }
}
walker ListComps {
    has claimed: dict[str, bool] = {};
    has comps: list[Comp] = [];
    can start with Root entry {
        print("root");
        for g in [here -->][?:GraphRoot] {
            visit :0: [g];
        }
    }
    can step_graph with GraphRoot entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print(here.name);
        for c in [here ->:Owns:->][?:Comp] {
            self.comps.append(c);
            visit :0: [c];
        }
    }
    can step_comp with Comp entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        for nxt in [here ->:Depends:->][?:Comp] {
            if nxt.cid not in self.claimed {
                self.comps.append(nxt);
            }
            visit :0: [nxt];
        }
    }
}
walker ImmediateDeps {
    has out: list[Comp] = [];
    can get with Comp entry {
        print(here.cid);
        for nxt in [here ->:Depends:->][?:Comp] {
            self.out.append(nxt);
        }
    }
}
def make_graph(name: str) -> GraphRoot {
    g: GraphRoot = GraphRoot(name=name);
    root ++> g;
    return g;
}
def add_component(graph_root: GraphRoot, cid: str, size: int = 0, is_used: bool = True) -> Comp {
    c: Comp = Comp(cid=cid, size=size, is_used=is_used);
    graph_root +>:Owns:+> c;
    return c;
}
def add_dependency(src: Comp, dst: Comp) -> None {
    src +>:Depends:+> dst;
}
def get_transitive_deps(comp: Comp) -> list[str] {
    w = comp spawn CollectTransitive(claimed={}, out=[]);
    res: list[str] = [];
    for cid in w.out {
        if cid != comp.cid {
            res.append(cid);
        }
    }
    return sorted(res);
}
def detect_circular_dependencies(graph_root: GraphRoot) -> list[list[str]] {
    lw = graph_root spawn ListComps(claimed={}, comps=[]);
    all_comps: list[Comp] = lw.comps;
    cycles: list[list[str]] = [];
    for comp in all_comps {
        iw = comp spawn ImmediateDeps(out=[]);
        for dep in iw.out {
            rw = dep spawn CollectTransitive(claimed={}, out=[]);
            found: bool = False;
            for cid in rw.out {
                if cid == comp.cid { found = True; }
            }
            if found {
                cyc: list[str] = [comp.cid, dep.cid];
                cyc = sorted(cyc);
                exists: bool = False;
                for ex in cycles {
                    if ex == cyc { exists = True; }
                }
                if not exists {
                    cycles.append(cyc);
                }
            }
        }
    }
    return cycles;
}
def find_unused_components(graph_root: GraphRoot) -> list[str] {
    lw = graph_root spawn ListComps(claimed={}, comps=[]);
    res: list[str] = [];
    for c in lw.comps {
        if not c.is_used {
            res.append(c.cid);
        }
    }
    return sorted(res);
}
def suggest_code_splits(graph_root: GraphRoot, size_threshold: int = 500) -> list[str] {
    lw = graph_root spawn ListComps(claimed={}, comps=[]);
    res: list[str] = [];
    for comp in lw.comps {
        w = comp spawn CollectTransitive(claimed={}, out=[]);
        trans: int = len(w.out) - 1;
        if trans >= 2 {
            res.append(comp.cid);
        }
        if trans < 2 {
            if comp.size >= size_threshold {
                res.append(comp.cid);
            }
        }
    }
    return sorted(res);
}
def generate_report(graph_root: GraphRoot) -> dict[str, int] {
    lw = graph_root spawn ListComps(claimed={}, comps=[]);
    total: int = len(lw.comps);
    unused: list[str] = find_unused_components(graph_root);
    cycles: list[list[str]] = detect_circular_dependencies(graph_root);
    splits: list[str] = suggest_code_splits(graph_root, 500);
    rep: dict[str, int] = {};
    rep["total_components"] = total;
    rep["unused_count"] = len(unused);
    rep["circular_count"] = len(cycles);
    rep["split_suggestions"] = len(splits);
    return rep;
}
with entry {
    g: GraphRoot = make_graph("demo");
    c1: Comp = add_component(g, "App", 600, True);
    c2: Comp = add_component(g, "Header", 100, True);
    add_dependency(c1, c2);
    root spawn ListComps(claimed={}, comps=[]);
}

test "diamond transitive revisit adversarial" {
    g = make_graph("diamond");
    a = add_component(g, "A", 100, True);
    b = add_component(g, "B", 100, True);
    c = add_component(g, "C", 100, True);
    d = add_component(g, "D", 100, True);
    add_dependency(a, b);
    add_dependency(a, c);
    add_dependency(b, d);
    add_dependency(c, d);
    deps = get_transitive_deps(a);
    assert(deps == ["B", "C", "D"]);
    deps_b = get_transitive_deps(b);
    assert(deps_b == ["D"]);
}
test "circular detection and unknown isolation" {
    g = make_graph("cycle_test");
    x = add_component(g, "X", 50, True);
    y = add_component(g, "Y", 50, True);
    z = add_component(g, "Z", 50, True);
    add_dependency(x, y);
    add_dependency(y, z);
    add_dependency(z, x);
    cycles = detect_circular_dependencies(g);
    assert(len(cycles) >= 1);
    g2 = make_graph("empty");
    assert(detect_circular_dependencies(g2) == []);
    assert(find_unused_components(g2) == []);
    assert(suggest_code_splits(g2, 500) == []);
    iso = add_component(g2, "Iso", 10, True);
    assert(get_transitive_deps(iso) == []);
}
test "unused and split suggestions" {
    g = make_graph("unused_split");
    app = add_component(g, "App", 800, True);
    dead = add_component(g, "Dead", 10, False);
    small = add_component(g, "Small", 10, True);
    big = add_component(g, "Big", 1000, True);
    add_dependency(app, small);
    add_dependency(app, big);
    add_dependency(app, dead);
    unused = find_unused_components(g);
    assert(unused == ["Dead"]);
    splits = suggest_code_splits(g, 500);
    assert("App" in splits);
    assert("Big" in splits);
    assert("Dead" not in splits);
}
test "generate report and sorted order" {
    g = make_graph("report");
    a = add_component(g, "A", 600, True);
    b = add_component(g, "B", 10, False);
    add_dependency(a, b);
    rep = generate_report(g);
    assert(rep["total_components"] == 2);
    assert(rep["unused_count"] == 1);
    assert(rep["circular_count"] == 0);
    assert(rep["split_suggestions"] == 1);
}
test "cycle skip does not hang diamond with extra edge order" {
    g = make_graph("diamond2");
    a = add_component(g, "A", 10, True);
    b = add_component(g, "B", 10, True);
    c = add_component(g, "C", 10, True);
    d = add_component(g, "D", 10, True);
    add_dependency(a, c);
    add_dependency(a, b);
    add_dependency(c, d);
    add_dependency(b, d);
    add_dependency(d, b);
    deps = get_transitive_deps(a);
    assert(sorted(deps) == ["B", "C", "D"]);
    cycles = detect_circular_dependencies(g);
    assert(len(cycles) >= 1);
}
