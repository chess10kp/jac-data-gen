"""timbrinded/shapelang#105 — transitive effect reachability (OSP lift)."""

obj EffectGraph {
    has funcs: dict[str, Function] = {};
    has unknown: set[str] = set();
}

node Function {
    has fid: str;
    has effects: list[str] = [];
}

edge Invokes {}

walker ReachFuncs {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Function entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        self.reached.append(here.fid);
        for callee in [here ->:Invokes:->][?:Function] {
            visit [callee];
        }
    }
}

def load_effect_graph(
    funcs: list[str],
    invokes: list[tuple[str, str]],
    effects: list[tuple[str, str]],
    unknown: list[str] | None = None,
) -> EffectGraph {
    g = EffectGraph(unknown=set(unknown or []));
    for fid in funcs {
        if fid not in g.funcs {
            fn = Function(fid=fid);
            root ++> fn;
            g.funcs[fid] = fn;
        }
    }
    for (src, dst) in invokes {
        a = g.funcs.get(src, None);
        b = g.funcs.get(dst, None);
        if a is not None and b is not None { a +>:Invokes:+> b; }
    }
    for (fn, eff) in effects {
        f = g.funcs.get(fn, None);
        if f is not None and eff not in f.effects {
            f.effects = f.effects + [eff];
        }
    }
    return g;
}

def _reachable_ids(g: EffectGraph, start: str) -> list[str] {
    anchor = g.funcs.get(start, None);
    if anchor is None { return []; }
    w = anchor spawn ReachFuncs(claimed={}, reached=[]);
    return w.reached;
}

def reachable_effects(g: EffectGraph, func_id: str) -> list[str] {
    if func_id in g.unknown { return []; }
    out: set[str] = set();
    for fid in _reachable_ids(g, func_id) {
        if fid in g.unknown { return []; }
        for eff in g.funcs[fid].effects { out.add(eff); }
    }
    return sorted(out);
}

def missing_effects(g: EffectGraph, func_id: str, declared: list[str]) -> list[str] {
    need = set(reachable_effects(g, func_id));
    have = set(declared);
    miss: list[str] = [];
    for e in sorted(need) {
        if e not in have { miss.append(e); }
    }
    return miss;
}

def has_unknown_reachable(g: EffectGraph, func_id: str) -> bool {
    for fid in _reachable_ids(g, func_id) {
        if fid in g.unknown { return True; }
    }
    return False;
}
