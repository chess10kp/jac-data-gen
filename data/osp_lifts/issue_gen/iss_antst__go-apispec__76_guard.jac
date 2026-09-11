"""Guard: antst/go-apispec#76."""

obj CallGraph { has handlers: dict[str, Handler] = {}; has entries: list[str] = []; }
node Handler { has name: str; }
node Route { has path: str; }
edge Calls {}
edge Registers {}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    can step with Handler entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Calls:->] else { disengage; };
    }
}

def load_callgraph(
    handlers: list[str],
    calls: list[tuple[str, str]],
    routes: list[tuple[str, str]],
    entries: list[str],
) -> CallGraph {
    mp: dict[str, Handler] = {};
    for h in handlers {
        hnd = Handler(name=h);
        root ++> hnd;
        mp[h] = hnd;
    }
    for (src, dst) in calls {
        a = mp.get(src, None);
        b = mp.get(dst, None);
        if a is not None and b is not None { a +>:Calls:+> b; }
    }
    for (handler, path) in routes {
        h = mp.get(handler, None);
        if h is not None {
            r = Route(path=path);
            root ++> r;
            h +>:Registers:+> r;
        }
    }
    return CallGraph(handlers=mp, entries=entries);
}

def reachable_handlers(g: CallGraph, `entry: str) -> list[str] {
    anchor = g.handlers.get(`entry, None);
    if anchor is None { return []; }
    w = anchor spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def exported_paths(g: CallGraph) -> list[str] {
    reachable: list[str] = [];
    for ent in g.entries {
        for h in reachable_handlers(g, ent) {
            if h not in reachable { reachable.append(h); }
        }
    }
    paths: list[str] = [];
    for hname in sorted(reachable) {
        anchor = g.handlers.get(hname, None);
        if anchor is None { continue; }
        for r in [anchor ->:Registers:->][?:Route] { paths.append(r.path); }
    }
    return sorted(paths);
}

test "chain reach exports route path" {
    g = load_callgraph(
        ["main", "setup", "register"],
        [("main", "setup"), ("setup", "register")],
        [("register", "/users")],
        ["main"],
    );
    assert reachable_handlers(g, "main") == ["main", "register", "setup"];
    assert exported_paths(g) == ["/users"];
}

test "call cycle still exports paths" {
    g = load_callgraph(
        ["main", "a", "b", "c", "register"],
        [
            ("main", "a"),
            ("a", "b"),
            ("b", "c"),
            ("c", "a"),
            ("c", "register"),
        ],
        [("register", "/ping")],
        ["main"],
    );
    assert reachable_handlers(g, "main") == ["a", "b", "c", "main", "register"];
    assert exported_paths(g) == ["/ping"];
}

test "diamond adversarial once per handler" {
    g = load_callgraph(
        ["main", "left", "right", "register"],
        [
            ("main", "left"),
            ("main", "right"),
            ("left", "register"),
            ("right", "register"),
        ],
        [("register", "/api")],
        ["main"],
    );
    assert reachable_handlers(g, "main") == ["left", "main", "register", "right"];
    assert exported_paths(g) == ["/api"];
}

test "multiple entries union paths" {
    g = load_callgraph(
        ["e1", "e2", "h1", "h2"],
        [("e1", "h1"), ("e2", "h2")],
        [("h1", "/one"), ("h2", "/two")],
        ["e1", "e2"],
    );
    assert exported_paths(g) == ["/one", "/two"];
}

test "unreachable routes omitted" {
    g = load_callgraph(
        ["main", "orphan"],
        [],
        [("orphan", "/hidden")],
        ["main"],
    );
    assert exported_paths(g) == [];
}

test "unknown entry tolerant" {
    g = load_callgraph(["solo"], [], [("solo", "/solo")], ["solo"]);
    assert reachable_handlers(g, "missing") == [];
    assert exported_paths(g) == ["/solo"];
}
