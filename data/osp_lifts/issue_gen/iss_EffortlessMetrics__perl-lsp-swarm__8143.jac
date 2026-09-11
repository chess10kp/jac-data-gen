"""EffortlessMetrics/perl-lsp-swarm#8143 — typed semantic edges (OSP lift)."""

obj SymbolStore {
    has stamp: int = 0;
}

node Symbol {
    has sym_id: str;
    has anchor: str;
}

edge Inherits: Symbol --> Symbol {
    has ord: int = 0;
}

edge Uses: Symbol --> Symbol {}
edge Tests: Symbol --> Symbol {}

walker AncestorWalker {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with Symbol entry {
        if here.sym_id in self.claimed {
            skip;
        }
        self.claimed[here.sym_id] = True;
        self.chain.append(here.sym_id);
        parents = [here ->:Inherits:->][?:Symbol];
        if not parents {
            disengage;
        }
        pick = parents[0];
        best = 9999;
        for p in parents {
            for e in [edge here ->:Inherits:-> p] {
                if e.ord < best {
                    best = e.ord;
                    pick = p;
                }
            }
        }
        visit [pick];
    }
}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for s in [-->][?:Symbol] {
            if s.sym_id == self.start {
                visit [s];
            }
        }
    }

    can step with Symbol entry {
        if here.sym_id in self.claimed {
            skip;
        }
        self.claimed[here.sym_id] = True;
        self.reached.append(here.sym_id);
        nxt: list[Symbol] = [];
        for p in [here ->:Inherits:->][?:Symbol] {
            nxt.append(p);
        }
        for p in [here ->:Uses:->][?:Symbol] {
            nxt.append(p);
        }
        for p in [here ->:Tests:->][?:Symbol] {
            nxt.append(p);
        }
        if nxt {
            visit nxt;
        } else {
            disengage;
        }
    }
}

def _find(sym_id: str) -> Symbol | None {
    for s in [-->][?:Symbol] {
        if s.sym_id == sym_id {
            return s;
        }
    }
    return None;
}

def load_symbols(
    entities: list[tuple[str, str]],
    parent_lists: list[tuple[str, list[str]]],
    uses: list[tuple[str, str]],
    tests: list[tuple[str, str]],
) -> SymbolStore {
    mp: dict[str, Symbol] = {};
    for (sid, anchor) in entities {
        if sid not in mp {
            n = Symbol(sym_id=sid, anchor=anchor);
            root ++> n;
            mp[sid] = n;
        }
    }
    for (child, parents) in parent_lists {
        ch = mp.get(child, None);
        if ch is None {
            continue;
        }
        for (i, par_id) in enumerate(parents) {
            par = mp.get(par_id, None);
            if par is not None {
                ch +>:Inherits(ord=i + 1):+> par;
            }
        }
    }
    for (src, dst) in uses {
        a = mp.get(src, None);
        b = mp.get(dst, None);
        if a is not None and b is not None {
            a +>:Uses:+> b;
        }
    }
    for (src, dst) in tests {
        a = mp.get(src, None);
        b = mp.get(dst, None);
        if a is not None and b is not None {
            a +>:Tests:+> b;
        }
    }
    return SymbolStore(stamp=1);
}

def ordered_parents(store: SymbolStore, symbol: str) -> list[str] {
    _ = store;
    anchor = _find(symbol);
    if anchor is None {
        return [];
    }
    pairs: list[tuple[int, str]] = [];
    for p in [anchor ->:Inherits:->][?:Symbol] {
        for e in [edge anchor ->:Inherits:-> p] {
            pairs.append((e.ord, p.sym_id));
        }
    }
    pairs.sort();
    out: list[str] = [];
    for (_o, nm) in pairs {
        out.append(nm);
    }
    return out;
}

def typed_refs(store: SymbolStore, src: str, kind: str) -> list[str] {
    _ = store;
    anchor = _find(src);
    if anchor is None {
        return [];
    }
    out: list[str] = [];
    if kind == "Uses" {
        for p in [anchor ->:Uses:->][?:Symbol] {
            out.append(p.sym_id);
        }
    } elif kind == "Tests" {
        for p in [anchor ->:Tests:->][?:Symbol] {
            out.append(p.sym_id);
        }
    } elif kind == "Inherits" {
        for p in [anchor ->:Inherits:->][?:Symbol] {
            out.append(p.sym_id);
        }
    }
    return sorted(out);
}

def ref_closure(store: SymbolStore, start: str) -> list[str] {
    _ = store;
    if _find(start) is None {
        return [];
    }
    w = root spawn ClosureWalker(start=start, claimed={}, reached=[]);
    return sorted(w.reached);
}

def ancestor_chain(store: SymbolStore, symbol: str) -> list[str] {
    _ = store;
    anchor = _find(symbol);
    if anchor is None {
        return [];
    }
    w = anchor spawn AncestorWalker(claimed={}, chain=[]);
    return w.chain;
}
