"""accidental-hedge-fund/agent-pipeline#809 — Symbol call-graph path queries."""

node Symbol {
    has sid: str;
}

edge Calls {}

obj SymbolGraph {
    has symbols: dict[str, Symbol] = {};
}

walker ForwardReach {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has max_hops: int = 3;
    has hops: int = 0;

    can step with Symbol entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.hits.append(here.sid);
        if self.hops >= self.max_hops { disengage; }
        for nb in [here ->:Calls:->][?:Symbol] {
            nb spawn ForwardReach(
                claimed=self.claimed,
                hits=self.hits,
                max_hops=self.max_hops,
                hops=self.hops + 1,
            );
        }
    }
}

walker PathCollect {
    has target: str = "";
    has max_hops: int = 4;
    has path: list[str] = [];
    has hits: dict[str, bool] = {};

    can step with Symbol entry {
        if here.sid in self.path { skip; }
        self.path = self.path + [here.sid];
        if here.sid == self.target and len(self.path) > 1 {
            for p in self.path { self.hits[p] = True; }
            skip;
        }
        if len(self.path) - 1 >= self.max_hops { skip; }
        visit [->:Calls:->][?:Symbol];
    }
}

walker CycleProbe {
    has target: str = "";
    has path: list[str] = [];
    has found: bool = False;

    can step with Symbol entry {
        if here.sid in self.path {
            if here.sid == self.target and len(self.path) > 0 {
                self.found = True;
            }
            skip;
        }
        self.path = self.path + [here.sid];
        if len(self.path) > 1 and here.sid == self.target {
            self.found = True;
            disengage;
        }
        visit [->:Calls:->][?:Symbol];
    }
}

def load_symbol_graph(
    symbols: list[str],
    calls: list[tuple[str, str]],
) -> SymbolGraph {
    g = SymbolGraph();
    for s in symbols {
        if s not in g.symbols {
            nd = Symbol(sid=s);
            root ++> nd;
            g.symbols[s] = nd;
        }
    }
    for (caller, callee) in calls {
        c1 = g.symbols.get(caller, None);
        c2 = g.symbols.get(callee, None);
        if c1 is not None and c2 is not None { c1 +>:Calls:+> c2; }
    }
    return g;
}

def call_paths(
    g: SymbolGraph,
    source: str,
    sink: str,
    max_hops: int = 4,
) -> list[str] {
    if source not in g.symbols or sink not in g.symbols { return []; }
    pending_cur: list[str] = [source];
    pending_path: list[list[str]] = [[source]];
    pending_seen: list[dict[str, bool]] = [{source: True}];
    hits: dict[str, bool] = {};
    idx = 0;
    while idx < len(pending_cur) {
        cur = pending_cur[idx];
        path = pending_path[idx];
        seen = pending_seen[idx];
        idx += 1;
        if len(path) - 1 > max_hops { continue; }
        fn = g.symbols.get(cur, None);
        if fn is None { continue; }
        for nb in [fn ->:Calls:->][?:Symbol] {
            if nb.sid in seen { continue; }
            npath: list[str] = [];
            for p in path { npath.append(p); }
            npath.append(nb.sid);
            nseen: dict[str, bool] = {};
            for (k, v) in seen.items() { nseen[k] = v; }
            nseen[nb.sid] = True;
            if nb.sid == sink and len(npath) > 1 {
                for p in npath { hits[p] = True; }
                continue;
            }
            pending_cur.append(nb.sid);
            pending_path.append(npath);
            pending_seen.append(nseen);
        }
    }
    return sorted(hits.keys());
}

def reachable_symbols(g: SymbolGraph, source: str, max_hops: int = 3) -> list[str] {
    nd = g.symbols.get(source, None);
    if nd is None { return []; }
    w = nd spawn ForwardReach(claimed={}, hits=[], max_hops=max_hops, hops=0);
    out: list[str] = [];
    for h in w.hits {
        if h != source { out.append(h); }
    }
    return sorted(out);
}

def has_cycle(g: SymbolGraph) -> bool {
    for (sid, nd) in g.symbols.items() {
        w = nd spawn CycleProbe(target=sid, path=[], found=False);
        if w.found { return True; }
    }
    return False;
}
