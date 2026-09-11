"""numba/numba#9316 — Per-function cache invalidation via global dependency reach."""

node JitFunc {
    has name: str;
}

node GlobalVar {
    has name: str;
}

edge UsesGlobal {}

edge Invalidates {}

obj CacheStore {
    has funcs: dict[str, JitFunc] = {};
    has global_vars: dict[str, GlobalVar] = {};
}

walker InvalidateWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with JitFunc entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
    }
}

def load_cache_graph(
    func_names: list[str],
    global_names: list[str],
    use_edges: list[tuple[str, str]],
) -> CacheStore {
    store = CacheStore();
    for fn in func_names {
        fnd = JitFunc(name=fn);
        root ++> fnd;
        store.funcs[fn] = fnd;
    }
    for gname in global_names {
        gnd = GlobalVar(name=gname);
        root ++> gnd;
        store.global_vars[gname] = gnd;
    }
    for (fn, gl) in use_edges {
        f = store.funcs.get(fn, None);
        gv = store.global_vars.get(gl, None);
        if f is not None and gv is not None {
            f +>:UsesGlobal:+> gv;
            gv +>:Invalidates:+> f;
        }
    }
    return store;
}

def invalidated_by_global(store: CacheStore, changed: list[str]) -> list[str] {
    acc: dict[str, bool] = {};
    for gl in changed {
        gnd = store.global_vars.get(gl, None);
        if gnd is None { continue; }
        for fn in [gnd ->:Invalidates:->][?:JitFunc] {
            if fn.name not in acc { acc[fn.name] = True; }
        }
    }
    return sorted(acc.keys());
}

def globals_for_func(store: CacheStore, func: str) -> list[str] {
    fnd = store.funcs.get(func, None);
    if fnd is None { return []; }
    out: list[str] = [];
    for gv in [fnd ->:UsesGlobal:->][?:GlobalVar] { out.append(gv.name); }
    return sorted(out);
}

def would_invalidate(store: CacheStore, func: str, global_name: str) -> bool {
    fnd = store.funcs.get(func, None);
    gnd = store.global_vars.get(global_name, None);
    if fnd is None or gnd is None { return False; }
    for gv in [fnd ->:UsesGlobal:->][?:GlobalVar] {
        if gv.name == global_name { return True; }
    }
    return False;
}
