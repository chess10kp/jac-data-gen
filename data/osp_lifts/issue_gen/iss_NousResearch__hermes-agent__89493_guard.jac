"""OSP lift: hierarchical Roadmap projection. Source: NousResearch/hermes-agent#89493."""

node Scope {
    has scope_id: str;
}

edge ChildOf {}
edge DependsOn {}
edge Refs {}

obj Roadmap {
    has scopes: dict[str, Scope];

    def resolve(sid: str) -> Scope | None {
        return self.scopes.get(sid);
    }
}

def build_roadmap(
    scopes: list[str],
    parent_edges: list[tuple[str, str]],
    dep_edges: list[tuple[str, str]],
    ref_edges: list[tuple[str, str]],
) -> Roadmap {
    g = Roadmap(scopes={});
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

def roadmap_children(g: Roadmap, scope_id: str) -> list[str] {
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

walker DescendantWalker {
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
        visit [->:ChildOf:->];
    }
}

def roadmap_closure(g: Roadmap, scope_id: str) -> list[str] {
    nd = g.resolve(scope_id);
    if nd is None {
        return [];
    }
    w = nd spawn DescendantWalker(claimed={}, out=[], origin=scope_id);
    return sorted(w.out);
}

walker HierarchyCycleWalker {
    has visited: dict[str, bool] = {};
    has on_stack: dict[str, bool] = {};
    has found: bool = False;

    can step with Scope entry {
        if here.scope_id in self.on_stack {
            self.found = True;
            skip;
        }
        if here.scope_id in self.visited {
            skip;
        }
        self.visited[here.scope_id] = True;
        self.on_stack[here.scope_id] = True;
        visit [->:ChildOf:->] else {
            disengage;
        }
        self.on_stack[here.scope_id] = False;
    }
}

def has_hierarchy_cycle(g: Roadmap) -> bool {
    visited: dict[str, bool] = {};
    for sid in sorted(g.scopes.keys()) {
        if sid in visited {
            continue;
        }
        nd = g.scopes[sid];
        w = nd spawn HierarchyCycleWalker(visited=visited, on_stack={}, found=False);
        if w.found {
            return True;
        }
        visited = w.visited;
    }
    return False;
}

test "portfolio children and closure" {
    g = build_roadmap(
        ["portfolio", "ws_a", "ws_b", "project", "epic"],
        [
            ("portfolio", "ws_a"),
            ("portfolio", "ws_b"),
            ("ws_a", "project"),
            ("ws_b", "project"),
            ("project", "epic"),
        ],
        [("ws_a", "project")],
        [("epic", "ws_a")],
    );
    assert roadmap_children(g, "portfolio") == ["ws_a", "ws_b"];
    assert roadmap_closure(g, "portfolio") == ["epic", "project", "ws_a", "ws_b"];
    assert has_hierarchy_cycle(g) == False;
}

test "diamond closure adversarial edge order" {
    g = build_roadmap(
        ["r", "a", "b", "c", "d"],
        [("r", "b"), ("r", "a"), ("a", "c"), ("b", "c"), ("c", "d")],
        [],
        [],
    );
    assert roadmap_closure(g, "r") == ["a", "b", "c", "d"];
    assert len(roadmap_closure(g, "r")) == 4;
}

test "hierarchy cycle once per scope" {
    g = build_roadmap(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
        [],
        [],
    );
    assert has_hierarchy_cycle(g) == True;
    assert roadmap_closure(g, "a") == ["b", "c"];
    assert len(roadmap_closure(g, "a")) == 2;
}

test "unknown scope tolerant" {
    g = build_roadmap(["x"], [], [], []);
    assert roadmap_children(g, "ghost") == [];
    assert roadmap_closure(g, "ghost") == [];
}
