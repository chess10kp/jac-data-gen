node Target { has tid: str; }
edge ImmediateDep {}
edge ProductDep {}

walker Discover {
    has visited: dict[str, bool] = {};
    has result: list[str] = [];
    can discover with Target entry {
        if here.tid in self.visited { skip; }
        self.visited[here.tid] = True;
        self.result.append(here.tid);
        print(here.tid);
        kids: list[Target] = [];
        for nxt in [here ->:ImmediateDep:->][?:Target] {
            kids.append(nxt);
        }
        for nxt in [here ->:ProductDep:->][?:Target] {
            kids.append(nxt);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def create_target(tid: str) -> Target {
    nd = Target(tid=tid);
    root ++> nd;
    return nd;
}

def add_immediate_dependency(src: Target, dst: Target) {
    src +>:ImmediateDep:+> dst;
}

def add_package_product_dependency(src: Target, dst: Target) {
    src +>:ProductDep:+> dst;
}

def add_dependency(src: Target, dst: Target, is_package_product: bool) {
    if is_package_product {
        src +>:ProductDep:+> dst;
    } else {
        src +>:ImmediateDep:+> dst;
    }
}

def compute_graph(start: Target) -> list[str] {
    init_visited: dict[str, bool] = {};
    init_result: list[str] = [];
    w = start spawn Discover(visited=init_visited, result=init_result);
    return w.result;
}

def transitive_closure(start: Target) -> list[str] {
    return compute_graph(start);
}

def reachable_tids(start: Target) -> list[str] {
    return compute_graph(start);
}

with entry {
    demo = Target(tid="demo");
    root ++> demo;
    dep = Target(tid="dep");
    root ++> dep;
    demo +>:ImmediateDep:+> dep;
    pkg = Target(tid="pkg");
    root ++> pkg;
    demo +>:ProductDep:+> pkg;
    w = demo spawn Discover(visited={}, result=[]);
    print(w.result);
}

test "diamond_mixed_edges_adversarial" {
    r = Target(tid="r");
    a = Target(tid="a");
    b = Target(tid="b");
    d = Target(tid="d");
    root ++> r; root ++> a; root ++> b; root ++> d;
    r +>:ImmediateDep:+> a;
    r +>:ProductDep:+> b;
    a +>:ImmediateDep:+> d;
    b +>:ProductDep:+> d;
    res = compute_graph(r);
    assert (sorted(res) == sorted(["r", "a", "b", "d"]));
}

test "diamond_mixed_edges_adversarial_reverse_insert" {
    r = Target(tid="r");
    a = Target(tid="a");
    b = Target(tid="b");
    d = Target(tid="d");
    root ++> r; root ++> a; root ++> b; root ++> d;
    r +>:ProductDep:+> b;
    r +>:ImmediateDep:+> a;
    b +>:ImmediateDep:+> d;
    a +>:ProductDep:+> d;
    res = compute_graph(r);
    assert (sorted(res) == sorted(["r", "a", "b", "d"]));
}

test "cycle_with_package_edge" {
    x = Target(tid="x");
    y = Target(tid="y");
    z = Target(tid="z");
    root ++> x; root ++> y; root ++> z;
    x +>:ImmediateDep:+> y;
    y +>:ProductDep:+> z;
    z +>:ImmediateDep:+> x;
    res = compute_graph(x);
    assert (sorted(res) == sorted(["x", "y", "z"]));
}

test "linear_chain_mixed_package_immediate" {
    r = Target(tid="r");
    a = Target(tid="a");
    b = Target(tid="b");
    c = Target(tid="c");
    root ++> r; root ++> a; root ++> b; root ++> c;
    r +>:ProductDep:+> a;
    a +>:ImmediateDep:+> b;
    b +>:ProductDep:+> c;
    res = compute_graph(r);
    assert (sorted(res) == sorted(["r", "a", "b", "c"]));
}

test "unknown_and_empty_graph_tolerance" {
    lone = Target(tid="lone");
    root ++> lone;
    res = compute_graph(lone);
    assert (res == ["lone"]);
    r2 = Target(tid="r2");
    a2 = Target(tid="a2");
    root ++> r2; root ++> a2;
    r2 +>:ProductDep:+> a2;
    res2 = compute_graph(r2);
    assert (sorted(res2) == sorted(["r2", "a2"]));
}
