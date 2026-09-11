"""Guard: Saanvi51/bigstardust-workspace#332."""

node StudyNode { has nid: str; }
edge Adjacent {}

obj StudyGraph {
    has nodes: dict[str, StudyNode] = {};
}

walker ComponentWalk {
    has claimed: dict[str, bool] = {};
    has comp: list[str] = [];

    can step with StudyNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.comp.append(here.nid);
        visit [->:Adjacent:->][?:StudyNode];
    }
}

def load_study_graph(nodes: list[str], edges: list[tuple[str, str]]) -> StudyGraph {
    g = StudyGraph();
    for nid in nodes {
        nd = StudyNode(nid=nid);
        root ++> nd;
        g.nodes[nid] = nd;
    }
    for (a, b) in edges {
        na = g.nodes.get(a, None);
        nb = g.nodes.get(b, None);
        if na is not None and nb is not None {
            na +>:Adjacent:+> nb;
            nb +>:Adjacent:+> na;
        }
    }
    return g;
}

def connected_components(graph: StudyGraph) -> list[list[str]] {
    seen: dict[str, bool] = {};
    comps: list[list[str]] = [];
    for start in sorted(graph.nodes.keys()) {
        if start in seen { continue; }
        w = graph.nodes[start] spawn ComponentWalk(claimed={}, comp=[]);
        for nid in w.comp { seen[nid] = True; }
        comps.append(sorted(w.comp));
    }
    return sorted(comps);
}

def component_count(graph: StudyGraph) -> int {
    return len(connected_components(graph));
}

test "two components" {
    g = load_study_graph(
        ["a", "b", "c", "d", "e"],
        [("a", "b"), ("b", "c"), ("d", "e")],
    );
    assert connected_components(g) == [["a", "b", "c"], ["d", "e"]];
    assert component_count(g) == 2;
}

test "diamond single component" {
    g = load_study_graph(
        ["hub", "left", "right", "bot"],
        [("right", "bot"), ("hub", "left"), ("left", "bot"), ("hub", "right")],
    );
    assert connected_components(g) == [["bot", "hub", "left", "right"]];
}

test "isolated nodes" {
    g = load_study_graph(["solo"], []);
    assert connected_components(g) == [["solo"]];
}
