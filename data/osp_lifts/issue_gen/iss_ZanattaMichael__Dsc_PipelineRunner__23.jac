"""ZanattaMichael/Dsc.PipelineRunner#23 — Kahn topological sort with cycle error."""

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
