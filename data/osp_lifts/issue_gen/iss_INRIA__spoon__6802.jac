"""INRIA/spoon#6802 — Wildcard type erasure reference walk with cycle guard."""

obj TypeGraph {
    has types: dict[str, TypeNode] = {};
    has erased: dict[str, str] = {};
}

node TypeNode {
    has tid: str;
}

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
