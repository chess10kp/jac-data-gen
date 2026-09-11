"""Guard: eugenemalaschuk-source/arch-linter-net#461."""

obj AnalysisGraph {
    has projects: dict[str, Project] = {};
    has phases: dict[str, Phase] = {};
}

node Project { has pid: str; }
node Phase { has name: str; }
edge ChildProject {}
edge PhaseDepends {}

def load_analysis_graph(
    projects: list[str],
    parent_edges: list[tuple[str, str | None]],
    phase_edges: list[tuple[str, str]],
) -> AnalysisGraph {
    g = AnalysisGraph();
    for pid in projects {
        if pid not in g.projects {
            nd = Project(pid=pid);
            root ++> nd;
            g.projects[pid] = nd;
        }
    }
    for (pid, par) in parent_edges {
        if par is None { continue; }
        child = g.projects.get(pid, None);
        parent = g.projects.get(par, None);
        if child is not None and parent is not None { parent +>:ChildProject:+> child; }
    }
    phase_names: dict[str, bool] = {};
    for (phase, dep) in phase_edges {
        phase_names[phase] = True;
        phase_names[dep] = True;
    }
    for pname in phase_names.keys() {
        if pname not in g.phases {
            ph = Phase(name=pname);
            root ++> ph;
            g.phases[pname] = ph;
        }
    }
    for (phase, dep) in phase_edges {
        a = g.phases.get(phase, None);
        b = g.phases.get(dep, None);
        if a is not None and b is not None { a +>:PhaseDepends:+> b; }
    }
    return g;
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with Project entry {
        parents = [here <-:ChildProject:<-][?:Project];
        if len(parents) == 0 { disengage; }
        p = parents[0];
        if p.pid in self.claimed { skip; }
        self.claimed[p.pid] = True;
        self.chain.append(p.pid);
        visit [p];
    }
}

def project_ancestors(g: AnalysisGraph, project_id: str) -> list[str] {
    start = g.projects.get(project_id, None);
    if start is None { return []; }
    w = start spawn AncestorWalk(claimed={}, chain=[]);
    return w.chain;
}

walker PhaseWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Phase entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.hits.append(here.name);
        visit [->:PhaseDepends:->][?:Phase];
    }
}

def phases_reachable_from(g: AnalysisGraph, seed_phases: list[str]) -> list[str] {
    seen: dict[str, bool] = {};
    for seed in seed_phases {
        nd = g.phases.get(seed, None);
        if nd is None { continue; }
        w = nd spawn PhaseWalk(claimed={}, hits=[]);
        for h in w.hits { seen[h] = True; }
    }
    return sorted(seen.keys());
}

test "project lineage and phase closure" {
    g = load_analysis_graph(
        ["root", "app", "tests"],
        [("root", None), ("app", "root"), ("tests", "app")],
        [("eval", "graph"), ("eval", "load"), ("graph", "load")],
    );
    assert project_ancestors(g, "tests") == ["app", "root"];
    assert phases_reachable_from(g, ["eval"]) == ["eval", "graph", "load"];
}

test "unknown project empty lineage" {
    g = load_analysis_graph(["solo"], [("solo", None)], []);
    assert project_ancestors(g, "missing") == [];
}

test "phase diamond multiset" {
    g = load_analysis_graph(
        ["p"],
        [("p", None)],
        [("top", "left"), ("top", "right"), ("left", "base"), ("right", "base")],
    );
    assert phases_reachable_from(g, ["top"]) == ["base", "left", "right", "top"];
}
