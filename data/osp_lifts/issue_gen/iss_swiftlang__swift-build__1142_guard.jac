node Resolver {
    has name: str = "resolver";
}
node Target {
    has tid: str;
    has is_pkg: bool = False;
}
edge Anchors {}
edge Depends {}

walker DiscoverWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can discover with Target entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        print(here.tid);
        kids: list[Target] = [];
        for nxt in [here ->:Depends:->][?:Target] {
            kids.append(nxt);
        }
        if len(kids) > 0 {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker PrintRootWalker {
    has dummy: str = "";
    can start_resolver with Resolver entry {
        print(here.name);
        disengage;
    }
    can start_target with Target entry {
        print(here.tid);
        disengage;
    }
}

def find_target(resolver: Resolver, tid: str) -> Target | None {
    for cand in [resolver ->:Anchors:->][?:Target] {
        if cand.tid == tid {
            return cand;
        }
    }
    return None;
}

def make_resolver() -> Resolver {
    r = Resolver(name="resolver");
    return r;
}

def add_target(resolver: Resolver, tid: str, is_pkg: bool) -> Target {
    for cand in [resolver ->:Anchors:->][?:Target] {
        if cand.tid == tid {
            return cand;
        }
    }
    nd = Target(tid=tid, is_pkg=is_pkg);
    resolver +>:Anchors:+> nd;
    return nd;
}

def add_dependency(resolver: Resolver, src_tid: str, dst_tid: str) -> None {
    src: Target | None = find_target(resolver, src_tid);
    dst: Target | None = find_target(resolver, dst_tid);
    if src is None { return; }
    if dst is None { return; }
    s: Target = src as Target;
    d: Target = dst as Target;
    s +>:Depends:+> d;
}

def get_dependencies(resolver: Resolver, tid: str) -> list[str] {
    ent: Target | None = find_target(resolver, tid);
    if ent is None { return []; }
    e: Target = ent as Target;
    out: list[str] = [];
    for nxt in [e ->:Depends:->][?:Target] {
        out.append(nxt.tid);
    }
    return out;
}

def compute_graph(resolver: Resolver, entry_tid: str) -> list[str] {
    ent: Target | None = find_target(resolver, entry_tid);
    if ent is None { return []; }
    e: Target = ent as Target;
    w = e spawn DiscoverWalker(claimed={}, order=[]);
    return w.order;
}

def is_reachable(resolver: Resolver, src_tid: str, dst_tid: str) -> bool {
    reached: list[str] = compute_graph(resolver, src_tid);
    for t in reached {
        if t == dst_tid { return True; }
    }
    return False;
}

with entry {
    r = Resolver(name="demo");
    root ++> r;
    a = Target(tid="A", is_pkg=False);
    b = Target(tid="B", is_pkg=True);
    r +>:Anchors:+> a;
    r +>:Anchors:+> b;
    a +>:Depends:+> b;
    w1 = a spawn DiscoverWalker(claimed={}, order=[]);
    print(w1.order);
    w2 = root spawn PrintRootWalker(dummy="hi");
    print(w2.dummy);
}

test "diamond revisit includes package products once" {
    r = make_resolver();
    add_target(r, "A", False);
    add_target(r, "B", True);
    add_target(r, "C", True);
    add_target(r, "D", False);
    add_dependency(r, "A", "B");
    add_dependency(r, "A", "C");
    add_dependency(r, "B", "D");
    add_dependency(r, "C", "D");
    res: list[str] = compute_graph(r, "A");
    assert(len(res) == 4);
    s: list[str] = sorted(res);
    assert(s[0] == "A");
    assert(s[1] == "B");
    assert(s[2] == "C");
    assert(s[3] == "D");
}

test "adversarial order diamond revisit before deeper first-visit" {
    r = make_resolver();
    add_target(r, "R", False);
    add_target(r, "X", False);
    add_target(r, "Y", True);
    add_target(r, "Z", False);
    add_dependency(r, "R", "Y");
    add_dependency(r, "R", "X");
    add_dependency(r, "X", "Z");
    add_dependency(r, "Y", "Z");
    res: list[str] = compute_graph(r, "R");
    assert(len(res) == 4);
    assert(sorted(res) == sorted(["R", "X", "Y", "Z"]));
    assert(is_reachable(r, "R", "Z") == True);
}

test "unknown id tolerance returns empty" {
    r = make_resolver();
    add_target(r, "A", False);
    res: list[str] = compute_graph(r, "MISSING");
    assert(len(res) == 0);
    deps: list[str] = get_dependencies(r, "MISSING");
    assert(len(deps) == 0);
    assert(is_reachable(r, "MISSING", "A") == False);
    assert(is_reachable(r, "A", "MISSING") == False);
}

test "cycle does not loop and includes all" {
    r = make_resolver();
    add_target(r, "X", False);
    add_target(r, "Y", True);
    add_target(r, "Z", False);
    add_dependency(r, "X", "Y");
    add_dependency(r, "Y", "Z");
    add_dependency(r, "Z", "X");
    res: list[str] = compute_graph(r, "X");
    assert(len(res) == 3);
    assert(sorted(res) == sorted(["X", "Y", "Z"]));
}

test "linear package product chain path reach" {
    r = make_resolver();
    add_target(r, "A", False);
    add_target(r, "P1", True);
    add_target(r, "P2", True);
    add_target(r, "B", False);
    add_dependency(r, "A", "P1");
    add_dependency(r, "P1", "P2");
    add_dependency(r, "P2", "B");
    res: list[str] = compute_graph(r, "A");
    assert(len(res) == 4);
    assert(is_reachable(r, "A", "B") == True);
    assert(is_reachable(r, "B", "A") == False);
    deps: list[str] = get_dependencies(r, "P1");
    assert(len(deps) == 1);
    assert(deps[0] == "P2");
}
