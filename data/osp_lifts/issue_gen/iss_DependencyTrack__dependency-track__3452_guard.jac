"""Guard: DependencyTrack/dependency-track#3452."""

obj DepGraph {
    has nodes: dict[str, Component] = {};
}

node Component { has cid: str; }
edge Depends {}

walker ForwardWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Component entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.reached.append(here.cid);
        visit [->:Depends:->] else { disengage; };
    }
}

walker ReverseWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Component entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.reached.append(here.cid);
        visit [<-:Depends:<-] else { disengage; };
    }
}

def load_dep_graph(
    components: list[str],
    depends_edges: list[tuple[str, str]],
) -> DepGraph {
    g = DepGraph();
    for cid in components {
        if cid not in g.nodes {
            nd = Component(cid=cid);
            root ++> nd;
            g.nodes[cid] = nd;
        }
    }
    for (parent, child) in depends_edges {
        p = g.nodes.get(parent, None);
        c = g.nodes.get(child, None);
        if p is not None and c is not None { p +>:Depends:+> c; }
    }
    return g;
}

def forward_closure(store: DepGraph, component_id: str) -> list[str] {
    anchor = store.nodes.get(component_id, None);
    if anchor is None { return []; }
    w = anchor spawn ForwardWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def reverse_introducers(store: DepGraph, leaf_id: str) -> list[str] {
    anchor = store.nodes.get(leaf_id, None);
    if anchor is None { return []; }
    w = anchor spawn ReverseWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

test "linear dependency closure and reverse introducers" {
    g = load_dep_graph(
        ["proj", "lib", "util", "leaf"],
        [("proj", "lib"), ("lib", "util"), ("util", "leaf")],
    );
    assert forward_closure(g, "proj") == ["leaf", "lib", "proj", "util"];
    assert reverse_introducers(g, "leaf") == ["leaf", "lib", "proj", "util"];
}

test "diamond adversarial forward closure" {
    g = load_dep_graph(
        ["hub", "left", "right", "leaf"],
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    );
    assert forward_closure(g, "hub") == ["hub", "leaf", "left", "right"];
}

test "cycle terminates once per component" {
    g = load_dep_graph(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert forward_closure(g, "a") == ["a", "b", "c"];
    assert reverse_introducers(g, "b") == ["a", "b", "c"];
}

test "unknown component tolerant" {
    g = load_dep_graph(["solo"], []);
    assert forward_closure(g, "missing") == [];
    assert reverse_introducers(g, "missing") == [];
}
