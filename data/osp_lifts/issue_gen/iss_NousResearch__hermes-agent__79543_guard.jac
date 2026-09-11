"""OSP lift: Writer primitives and attempt fencing. Source: NousResearch/hermes-agent#79543."""

class FenceError(ValueError) {}

node Scope {
    has scope_id: str;
    has active_attempt: str | None = None;
    has buffer: list[str] = [];
}

edge ChildOf {}
edge DependsOn {}
edge Refs {}

obj WriterStore {
    has scopes: dict[str, Scope];

    def resolve(sid: str) -> Scope | None {
        return self.scopes.get(sid);
    }
}

def build_writer_store(
    scopes: list[str],
    parent_edges: list[tuple[str, str]],
    dep_edges: list[tuple[str, str]],
    ref_edges: list[tuple[str, str]],
) -> WriterStore {
    g = WriterStore(scopes={});
    for sid in scopes {
        nd = Scope(scope_id=sid);
        root ++> nd;
        g.scopes[sid] = nd;
    }
    for (parent, child) in parent_edges {
        p = g.scopes.get(parent);
        c = g.scopes.get(child);
        if p is not None and c is not None {
            p +>:ChildOf:+> c;
        }
    }
    for (blocker, blocked) in dep_edges {
        b = g.scopes.get(blocker);
        t = g.scopes.get(blocked);
        if b is not None and t is not None {
            b +>:DependsOn:+> t;
        }
    }
    for (src, dst) in ref_edges {
        s = g.scopes.get(src);
        d = g.scopes.get(dst);
        if s is not None and d is not None {
            s +>:Refs:+> d;
        }
    }
    return g;
}

def writer_children(g: WriterStore, scope_id: str) -> list[str] {
    nd = g.resolve(scope_id);
    if nd is None {
        return [];
    }
    out: list[str] = [];
    for c in [nd ->:ChildOf:->][?:Scope] {
        out.append(c.scope_id);
    }
    return sorted(out);
}

def begin_attempt(g: WriterStore, scope_id: str, attempt_id: str) -> bool {
    nd = g.resolve(scope_id);
    if nd is None {
        return False;
    }
    if nd.active_attempt is not None {
        return False;
    }
    nd.active_attempt = attempt_id;
    return True;
}

def write_primitive(
    g: WriterStore, scope_id: str, attempt_id: str, primitive: str
) -> bool {
    nd = g.resolve(scope_id);
    if nd is None {
        return False;
    }
    if nd.active_attempt != attempt_id {
        return False;
    }
    nd.buffer = nd.buffer + [primitive];
    return True;
}

def commit_attempt(g: WriterStore, scope_id: str, attempt_id: str) -> list[str] {
    nd = g.resolve(scope_id);
    if nd is None {
        return [];
    }
    if nd.active_attempt != attempt_id {
        raise FenceError("attempt not active");
    }
    out = list(nd.buffer);
    nd.buffer = [];
    nd.active_attempt = None;
    return out;
}

walker DepReachWalker {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    has origin: str = "";

    can step with Scope entry {
        if here.scope_id in self.claimed {
            skip;
        }
        self.claimed[here.scope_id] = True;
        if here.scope_id != self.origin {
            self.out.append(here.scope_id);
        }
        visit [->:DependsOn:->];
    }
}

def reachable_scopes(g: WriterStore, scope_id: str) -> list[str] {
    nd = g.resolve(scope_id);
    if nd is None {
        return [];
    }
    w = nd spawn DepReachWalker(claimed={}, out=[], origin=scope_id);
    return sorted(w.out);
}

walker InvalidateCollect {
    has claimed: dict[str, bool] = {};
    has targets: list[Scope] = [];

    can step with Scope entry {
        if here.scope_id in self.claimed {
            skip;
        }
        self.claimed[here.scope_id] = True;
        self.targets.append(here);
        visit [->:ChildOf:->];
        visit [->:DependsOn:->];
    }
}

def invalidate_downstream(g: WriterStore, scope_id: str) -> list[str] {
    nd = g.resolve(scope_id);
    if nd is None {
        return [];
    }
    w = nd spawn InvalidateCollect(claimed={}, targets=[]);
    cleared: list[str] = [];
    for sc in w.targets {
        had = (sc.active_attempt is not None) or (len(sc.buffer) > 0);
        sc.active_attempt = None;
        sc.buffer = [];
        if had {
            cleared.append(sc.scope_id);
        }
    }
    return sorted(cleared);
}

test "fencing commit and children" {
    g = build_writer_store(
        ["portfolio", "ws", "project", "task"],
        [("portfolio", "ws"), ("ws", "project"), ("project", "task")],
        [("ws", "project"), ("project", "task")],
        [("task", "ws")],
    );
    assert writer_children(g, "portfolio") == ["ws"];
    assert begin_attempt(g, "project", "a1") == True;
    assert begin_attempt(g, "project", "a2") == False;
    assert write_primitive(g, "project", "a1", "draft") == True;
    assert commit_attempt(g, "project", "a1") == ["draft"];
    try {
        commit_attempt(g, "project", "a1");
        assert False, "expected FenceError";
    } except FenceError {
        assert True;
    }
}

test "diamond dep reach adversarial order" {
    g = build_writer_store(
        ["r", "a", "b", "c"],
        [],
        [("r", "b"), ("r", "a"), ("a", "c"), ("b", "c")],
        [],
    );
    assert reachable_scopes(g, "r") == ["a", "b", "c"];
    assert len(reachable_scopes(g, "r")) == 3;
}

test "invalidate clears fenced downstream" {
    g = build_writer_store(
        ["portfolio", "ws", "project", "task"],
        [("portfolio", "ws"), ("ws", "project"), ("project", "task")],
        [("ws", "project"), ("project", "task")],
        [],
    );
    assert begin_attempt(g, "task", "t1") == True;
    assert write_primitive(g, "task", "t1", "wip") == True;
    assert invalidate_downstream(g, "portfolio") == ["task"];
    assert begin_attempt(g, "task", "t2") == True;
    assert commit_attempt(g, "task", "t2") == [];
}

test "unknown scope tolerant" {
    g = build_writer_store(["x"], [], [], []);
    assert writer_children(g, "ghost") == [];
    assert reachable_scopes(g, "ghost") == [];
    assert invalidate_downstream(g, "ghost") == [];
}
