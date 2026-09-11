"""Guard: Ankit6149/hardware-studio#40."""

obj ProductGraph {
    has parts: dict[str, Part] = {};
}

node Part { has pid: str; }
edge Contains {}
edge Depends {}

walker ImpactWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Part entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.reached.append(here.pid);
        visit [->:Contains:->][?:Part];
        visit [->:Depends:->][?:Part];
    }
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with Part entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.chain.append(here.pid);
        parents = [here <-:Contains:<-][?:Part];
        if not parents { disengage; }
        pick = parents[0];
        for p in parents {
            if p.pid < pick.pid { pick = p; }
        }
        visit [pick];
    }
}

def load_product_graph(
    parts: list[str],
    contains_edges: list[tuple[str, str]],
    depends_edges: list[tuple[str, str]],
) -> ProductGraph {
    g = ProductGraph();
    for pid in parts {
        if pid not in g.parts {
            nd = Part(pid=pid);
            root ++> nd;
            g.parts[pid] = nd;
        }
    }
    for (parent, child) in contains_edges {
        p = g.parts.get(parent, None);
        c = g.parts.get(child, None);
        if p is not None and c is not None { p +>:Contains:+> c; }
    }
    for (src, dst) in depends_edges {
        s = g.parts.get(src, None);
        d = g.parts.get(dst, None);
        if s is not None and d is not None { s +>:Depends:+> d; }
    }
    return g;
}

def impact_set(g: ProductGraph, part_id: str) -> list[str] {
    anchor = g.parts.get(part_id, None);
    if anchor is None { return []; }
    w = anchor spawn ImpactWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def ancestor_trace(g: ProductGraph, part_id: str) -> list[str] {
    anchor = g.parts.get(part_id, None);
    if anchor is None { return []; }
    w = anchor spawn AncestorWalk(claimed={}, chain=[]);
    return w.chain;
}

test "contains and depends impact radius" {
    g = load_product_graph(
        ["assy", "pcb", "fw", "req"],
        [("assy", "pcb"), ("pcb", "fw")],
        [("fw", "req")],
    );
    assert impact_set(g, "assy") == ["assy", "fw", "pcb", "req"];
    assert ancestor_trace(g, "fw") == ["fw", "pcb", "assy"];
}

test "diamond adversarial impact set" {
    g = load_product_graph(
        ["hub", "left", "right", "leaf"],
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
        [],
    );
    assert impact_set(g, "hub") == ["hub", "leaf", "left", "right"];
}

test "contains cycle ancestor trace terminates" {
    g = load_product_graph(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
        [],
    );
    assert ancestor_trace(g, "a") == ["a", "c", "b"];
}

test "unknown part tolerant" {
    g = load_product_graph(["solo"], [], []);
    assert impact_set(g, "missing") == [];
    assert ancestor_trace(g, "missing") == [];
}
