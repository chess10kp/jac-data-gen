"""Guard: INRIA/spoon#6802."""

obj TypeGraph {
    has types: dict[str, TypeNode] = {};
    has erased: dict[str, str] = {};
}
node TypeNode { has tid: str; }
edge BoundRef {}

walker ChainWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    can step with TypeNode entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.chain.append(here.tid);
        visit [->:BoundRef:->] else { disengage; };
    }
}

def load_type_graph(
    types: list[str],
    bound_refs: list[tuple[str, str]],
    erased: list[tuple[str, str]],
) -> TypeGraph {
    g = TypeGraph();
    for tid in types {
        if tid not in g.types {
            nd = TypeNode(tid=tid);
            root ++> nd;
            g.types[tid] = nd;
        }
    }
    for (src, dst) in bound_refs {
        a = g.types.get(src, None);
        b = g.types.get(dst, None);
        if a is not None and b is not None { a +>:BoundRef:+> b; }
    }
    for (tid, name) in erased {
        if tid in g.types { g.erased[tid] = name; }
    }
    return g;
}

def erasure_chain(g: TypeGraph, type_id: str) -> list[str] {
    anchor = g.types.get(type_id, None);
    if anchor is None { return []; }
    w = anchor spawn ChainWalk(claimed={}, chain=[]);
    return w.chain;
}

def erasure_of(g: TypeGraph, type_id: str) -> str {
    chain = erasure_chain(g, type_id);
    if not chain { return "Object"; }
    last = chain[len(chain) - 1];
    return g.erased.get(last, "Object");
}

test "wildcard erasure follows bound chain" {
    g = load_type_graph(
        ["wildcard", "bound_E", "E"],
        [("wildcard", "bound_E"), ("bound_E", "E")],
        [("E", "Object"), ("bound_E", "Object")],
    );
    assert erasure_chain(g, "wildcard") == ["wildcard", "bound_E", "E"];
    assert erasure_of(g, "wildcard") == "Object";
}

test "cyclic bound refs terminate erasure" {
    g = load_type_graph(
        ["w", "b", "c"],
        [("w", "b"), ("b", "c"), ("c", "w")],
        [("w", "Object")],
    );
    assert erasure_chain(g, "w") == ["w", "b", "c"];
    assert erasure_of(g, "w") == "Object";
}

test "lower bounded wildcard erases to object" {
    g = load_type_graph(
        ["lower", "object_bound"],
        [("lower", "object_bound")],
        [("object_bound", "Object")],
    );
    assert erasure_of(g, "lower") == "Object";
}

test "unknown type tolerant" {
    g = load_type_graph(["solo"], [], []);
    assert erasure_chain(g, "missing") == [];
    assert erasure_of(g, "missing") == "Object";
}
