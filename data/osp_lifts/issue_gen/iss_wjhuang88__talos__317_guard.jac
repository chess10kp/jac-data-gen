"""Guard: wjhuang88/talos#317."""

obj SymGraph { has symbols: dict[str, Symbol] = {}; }
node Symbol { has sid: str; }
edge Refers {}

def load_symbol_graph(
    symbols: list[str],
    refs: list[tuple[str, str]],
) -> SymGraph {
    g = SymGraph();
    for sid in symbols {
        if sid not in g.symbols {
            nd = Symbol(sid=sid);
            root ++> nd;
            g.symbols[sid] = nd;
        }
    }
    for (src, dst) in refs {
        a = g.symbols.get(src, None);
        b = g.symbols.get(dst, None);
        if a is not None and b is not None { a +>:Refers:+> b; }
    }
    return g;
}

walker RefWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Symbol entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.hits.append(here.sid);
        visit [->:Refers:->][?:Symbol];
    }
}

def reference_closure(g: SymGraph, symbol_id: str) -> list[str] {
    start = g.symbols.get(symbol_id, None);
    if start is None { return []; }
    w = start spawn RefWalk(claimed={}, hits=[]);
    return sorted(w.hits);
}

test "diamond reference closure" {
    g = load_symbol_graph(
        ["foo", "a", "b", "c"],
        [("foo", "a"), ("foo", "b"), ("a", "c"), ("b", "c")],
    );
    assert reference_closure(g, "foo") == ["a", "b", "c", "foo"];
}

test "unknown symbol empty" {
    g = load_symbol_graph(["solo"], []);
    assert reference_closure(g, "missing") == [];
}

test "adversarial edge order same multiset" {
    g = load_symbol_graph(
        ["root", "x", "y"],
        [("root", "y"), ("root", "x"), ("y", "x")],
    );
    assert reference_closure(g, "root") == ["root", "x", "y"];
}
