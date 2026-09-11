"""Guard: ZanattaMichael/Dsc.PipelineRunner#23."""

obj ResourceGraph { has nodes: dict[str, Resource] = {}; }
node Resource { has name: str; }
edge DependsOn {}

def load_resources(
    names: list[str],
    depends: dict[str, list[str]],
) -> ResourceGraph {
    g = ResourceGraph();
    for name in names {
        if name not in g.nodes {
            nd = Resource(name=name);
            root ++> nd;
            g.nodes[name] = nd;
        }
    }
    for (name, blockers) in depends.items() {
        tgt = g.nodes.get(name, None);
        if tgt is None { continue; }
        for blocker in blockers {
            src = g.nodes.get(blocker, None);
            if src is None { raise KeyError("missing resource: " + blocker); }
            src +>:DependsOn:+> tgt;
        }
    }
    return g;
}

def sort_depends_on(g: ResourceGraph) -> list[str] {
    indeg: dict[str, int] = {};
    for (name, nd) in g.nodes.items() {
        indeg[name] = len([nd <-:DependsOn:<-][?:Resource]);
    }
    ready = sorted([n for (n, d) in indeg.items() if d == 0]);
    out: list[str] = [];
    while ready {
        cur = ready.pop(0);
        out.append(cur);
        nd = g.nodes.get(cur, None);
        if nd is None { continue; }
        for dep in [nd ->:DependsOn:->][?:Resource] {
            indeg[dep.name] -= 1;
            if indeg[dep.name] == 0 { ready.append(dep.name); }
        }
        ready = sorted(ready);
    }
    if len(out) != len(g.nodes) { raise ValueError("cycle"); }
    return out;
}

test "linear and diamond order" {
    g = load_resources(["A", "B", "C"], {"B": ["A"], "C": ["B"]});
    assert sort_depends_on(g) == ["A", "B", "C"];
    g2 = load_resources(
        ["hub", "left", "right", "leaf"],
        {"left": ["hub"], "right": ["hub"], "leaf": ["left", "right"]},
    );
    assert sort_depends_on(g2) == ["hub", "left", "right", "leaf"];
}

test "cycle error" {
    g = load_resources(["X", "Y"], {"X": ["Y"], "Y": ["X"]});
    failed = False;
    try { sort_depends_on(g); }
    except ValueError { failed = True; }
    assert failed;
}

test "missing reference error" {
    failed = False;
    try { load_resources(["A"], {"A": ["missing"]}); }
    except KeyError { failed = True; }
    assert failed;
}
