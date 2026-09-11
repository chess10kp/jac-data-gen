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
