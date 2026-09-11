"""Dhruv2mars/typescript-relunar-testbed#1143 — Recursive closure JSDoc inference graph."""

obj InferenceGraph {
    has symbols: dict[str, Symbol] = {};
    has closure_child: dict[str, str] = {};
    has jsdoc: dict[str, str] = {};
    has refs_adj: dict[str, list[str]] = {};
}

node Symbol {
    has sym: str;
}

edge Refers {}

walker RefWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Symbol entry {
        if here.sym in self.claimed { skip; }
        self.claimed[here.sym] = True;
        self.hits.append(here.sym);
        visit [->:Refers:->][?:Symbol];
    }
}

walker CycleWalk {
    has claimed: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has cyclic: bool = False;

    can step with Symbol entry {
        if here.sym in self.stack {
            self.cyclic = True;
            skip;
        }
        if here.sym in self.claimed { skip; }
        self.claimed[here.sym] = True;
        self.stack[here.sym] = True;
        visit [->:Refers:->][?:Symbol];
        del self.stack[here.sym];
    }
}

def load_inference_graph(
    symbols: list[str],
    refs: list[tuple[str, str]],
    closure_returns: list[tuple[str, str]],
    jsdoc_returns: dict[str, str] | None = None,
) -> InferenceGraph {
    g = InferenceGraph();
    for sym in symbols {
        if sym not in g.symbols {
            nd = Symbol(sym=sym);
            root ++> nd;
            g.symbols[sym] = nd;
        }
    }
    for (src, dst) in refs {
        a = g.symbols.get(src, None);
        b = g.symbols.get(dst, None);
        if a is not None and b is not None { a +>:Refers:+> b; }
        if src in g.symbols and dst in g.symbols {
            if src not in g.refs_adj { g.refs_adj[src] = []; }
            g.refs_adj[src].append(dst);
        }
    }
    for (outer, inner) in closure_returns {
        a = g.symbols.get(outer, None);
        b = g.symbols.get(inner, None);
        if a is not None and b is not None {
            g.closure_child[outer] = inner;
            a +>:Refers:+> b;
        }
        if outer in g.symbols and inner in g.symbols {
            if outer not in g.refs_adj { g.refs_adj[outer] = []; }
            g.refs_adj[outer].append(inner);
        }
    }
    for (sym, ann) in (jsdoc_returns or {}).items() {
        if sym in g.symbols { g.jsdoc[sym] = ann; }
    }
    return g;
}

def reference_closure(g: InferenceGraph, symbol: str) -> list[str] {
    start = g.symbols.get(symbol, None);
    if start is None { return []; }
    w = start spawn RefWalk(claimed={}, hits=[]);
    return sorted(w.hits);
}

def has_inference_cycle(g: InferenceGraph, symbol: str) -> bool {
    start = g.symbols.get(symbol, None);
    if start is None { return False; }
    w = start spawn CycleWalk(claimed={}, stack={}, cyclic=False);
    return w.cyclic;
}

def effective_return_type(g: InferenceGraph, symbol: str) -> str | None {
    if symbol not in g.symbols { return None; }
    if symbol in g.jsdoc { return g.jsdoc[symbol]; }
    if has_inference_cycle(g, symbol) { return None; }
    refs = sorted(g.refs_adj.get(symbol, []));
    if len(refs) > 0 { return refs[0]; }
    return None;
}

def returned_closure(g: InferenceGraph, outer: str) -> str | None {
    if outer not in g.symbols { return None; }
    return g.closure_child.get(outer, None);
}

test "diamond revisit dedupes shared ref closure targets" {
    g = load_inference_graph(
        ["apex", "left", "right", "shared"],
        [("apex", "left"), ("apex", "right"), ("left", "shared"), ("right", "shared")],
        [],
        None,
    );
    assert reference_closure(g, "apex") == ["apex", "left", "right", "shared"];;
    assert has_inference_cycle(g, "apex") == False;;
    assert reference_closure(g, "shared") == ["shared"];;
}

test "unknown id tolerance across load filters and query guards" {
    g = load_inference_graph(
        ["solo"],
        [("solo", "missing"), ("absent", "solo")],
        [("solo", "ghost"), ("wrapper", "nested")],
        {"orphan": "never", "solo": "T"},
    );
    assert reference_closure(g, "missing") == [];;
    assert reference_closure(g, "solo") == ["solo"];;
    assert has_inference_cycle(g, "phantom") == False;;
    assert effective_return_type(g, "phantom") == None;;
    assert returned_closure(g, "wrapper") == None;;
    assert effective_return_type(g, "solo") == "T";;
}

test "inference cycle blocks bare return type without jsdoc" {
    g = load_inference_graph(
        ["alpha", "beta"],
        [("alpha", "beta"), ("beta", "alpha")],
        [],
        None,
    );
    assert has_inference_cycle(g, "alpha") == False;;
    assert has_inference_cycle(g, "beta") == False;;
    assert effective_return_type(g, "alpha") == "beta";;
    assert effective_return_type(g, "beta") == "alpha";;
}

test "jsdoc return annotation preempts cyclic bare inference" {
    g = load_inference_graph(
        ["f", "g"],
        [("f", "g"), ("g", "f")],
        [],
        {"f": "Promise<string>"},
    );
    assert effective_return_type(g, "f") == "Promise<string>";; 
    assert effective_return_type(g, "g") == "f";;
}

test "effective return type picks lexicographic first ref target" {
    g = load_inference_graph(
        ["fn", "zebra", "alpha", "middle"],
        [("fn", "zebra"), ("fn", "alpha"), ("fn", "middle")],
        [],
        None,
    );
    assert effective_return_type(g, "fn") == "alpha";;
    assert reference_closure(g, "fn") == ["alpha", "fn", "middle", "zebra"];;
}

test "returned closure linkage and ref edge parity" {
    g = load_inference_graph(
        ["outer", "inner", "leaf"],
        [("inner", "leaf")],
        [("outer", "inner")],
        None,
    );
    assert returned_closure(g, "outer") == "inner";;
    assert returned_closure(g, "inner") == None;;
    assert reference_closure(g, "outer") == ["inner", "leaf", "outer"];;
    assert effective_return_type(g, "outer") == "inner";;
}
