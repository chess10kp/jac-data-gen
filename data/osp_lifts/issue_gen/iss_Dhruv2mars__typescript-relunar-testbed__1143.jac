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
