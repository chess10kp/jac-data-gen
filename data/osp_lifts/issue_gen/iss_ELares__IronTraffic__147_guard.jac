"""Guard: ELares/IronTraffic#147."""

node Unit { has uid: str; }
edge UpstreamOf {}

obj CompileGraph {
    has units: dict[str, Unit] = {};
    has dirty: dict[str, bool] = {};
}

walker ReverseWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Unit entry {
        if here.uid in self.claimed { skip; }
        self.claimed[here.uid] = True;
        self.reached.append(here.uid);
        visit [->:UpstreamOf:->][?:Unit];
    }
}

def load_compile_graph(units: list[str], depends: list[tuple[str, str]]) -> CompileGraph {
    g = CompileGraph();
    for uid in units {
        nd = Unit(uid=uid);
        root ++> nd;
        g.units[uid] = nd;
    }
    for (upstream, downstream) in depends {
        u = g.units.get(upstream, None);
        d = g.units.get(downstream, None);
        if u is not None and d is not None { u +>:UpstreamOf:+> d; }
    }
    return g;
}

def reverse_dependents(graph: CompileGraph, unit_id: str) -> list[str] {
    nd = graph.units.get(unit_id, None);
    if nd is None { return []; }
    w = nd spawn ReverseWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def mark_dirty(graph: CompileGraph, changed: list[str]) -> list[str] {
    dirty: dict[str, bool] = {};
    for uid in changed {
        if not (uid in graph.units) { continue; }
        for dep in reverse_dependents(graph, uid) {
            dirty[dep] = True;
        }
    }
    graph.dirty = dirty;
    out: list[str] = [];
    for k in dirty.keys() { out.append(k); }
    return sorted(out);
}

def is_dirty(graph: CompileGraph, unit_id: str) -> bool {
    return graph.dirty.get(unit_id, False);
}

test "cert change dirties chain" {
    g = load_compile_graph(
        ["cert", "listener", "route", "table"],
        [("cert", "listener"), ("listener", "route"), ("route", "table")],
    );
    assert reverse_dependents(g, "cert") == ["cert", "listener", "route", "table"];
    assert mark_dirty(g, ["cert"]) == ["cert", "listener", "route", "table"];
    assert is_dirty(g, "route");
}

test "upstream fan-out dirty set" {
    g = load_compile_graph(
        ["upstream", "cluster", "route_a", "route_b"],
        [
            ("upstream", "cluster"),
            ("cluster", "route_a"),
            ("cluster", "route_b"),
        ],
    );
    assert mark_dirty(g, ["upstream"]) == [
        "cluster",
        "route_a",
        "route_b",
        "upstream",
    ];
}

test "diamond reverse dependents" {
    g = load_compile_graph(
        ["hub", "left", "right", "bot"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "bot"),
            ("right", "bot"),
        ],
    );
    assert reverse_dependents(g, "hub") == ["bot", "hub", "left", "right"];
}
