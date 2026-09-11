"""StellarChainproof/StellarChainproofs#66 — Multi-hop call-graph reentrancy path detection."""

node Func {
    has fid: str;
    has contract: str;
}

edge Calls {}

obj CallGraph {
    has funcs: dict[str, Func] = {};
    has unfinalized: dict[str, bool] = {};
}

walker ChainWalk {
    has origin: str;
    has origin_fid: str;
    has max_hops: int;
    has unfinalized: dict[str, bool];
    has path: list[str] = [];
    has hits: dict[str, bool] = {};

    can step with Func entry {
        if here.fid in self.path {
            skip;
        }
        self.path = self.path + [here.fid];
        if len(self.path) - 1 > self.max_hops {
            skip;
        }
        if here.fid != self.origin_fid and here.contract == self.origin and len(self.path) > 1 {
            unfinal = False;
            for p in self.path {
                if self.unfinalized.get(p, False) { unfinal = True; }
            }
            if unfinal {
                for p in self.path { self.hits[p] = True; }
            }
        }
        visit [->:Calls:->][?:Func];
    }
}

walker CrossContractWalk {
    has origin: str = "";
    has max_hops: int = 3;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has depth: int = 0;

    can step with Func entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        if here.fid != self.origin { self.hits.append(here.fid); }
        if self.depth >= self.max_hops { disengage; }
        self.depth += 1;
        for nb in [here ->:Calls:->][?:Func] {
            if nb.contract != here.contract { visit nb; }
        }
    }
}

def load_call_graph(
    funcs: list[tuple[str, str]],
    calls: list[tuple[str, str]],
    unfinalized: list[str],
) -> CallGraph {
    g = CallGraph();
    for (fid, contract) in funcs {
        if fid not in g.funcs {
            nd = Func(fid=fid, contract=contract);
            root ++> nd;
            g.funcs[fid] = nd;
        }
    }
    for (caller, callee) in calls {
        c1 = g.funcs.get(caller, None);
        c2 = g.funcs.get(callee, None);
        if c1 is not None and c2 is not None { c1 +>:Calls:+> c2; }
    }
    for fid in unfinalized { g.unfinalized[fid] = True; }
    return g;
}

def reentrant_chains(
    g: CallGraph,
    entry_func: str,
    max_hops: int = 3,
) -> list[str] {
    nd = g.funcs.get(entry_func, None);
    if nd is None { return []; }
    w = nd spawn ChainWalk(
        origin=nd.contract,
        origin_fid=entry_func,
        max_hops=max_hops,
        unfinalized=g.unfinalized,
        path=[],
        hits={},
    );
    return sorted(w.hits.keys());
}

def cross_contract_hops(g: CallGraph, entry_func: str, max_hops: int = 3) -> list[str] {
    nd = g.funcs.get(entry_func, None);
    if nd is None { return []; }
    pending: list[tuple[str, int]] = [(entry_func, 0)];
    claimed: dict[str, bool] = {entry_func: True};
    hits: dict[str, bool] = {};
    while len(pending) > 0 {
        (cur, depth) = pending.pop(0);
        if depth >= max_hops { continue; }
        fn = g.funcs.get(cur, None);
        if fn is None { continue; }
        for nb in [fn ->:Calls:->][?:Func] {
            if nb.contract != fn.contract {
                hits[nb.fid] = True;
            }
            if nb.fid not in claimed {
                claimed[nb.fid] = True;
                pending.append((nb.fid, depth + 1));
            }
        }
    }
    return sorted(hits.keys());
}

def is_guarded_chain(g: CallGraph, chain: list[str], guarded: set[str]) -> bool {
    for fid in chain {
        if fid not in guarded { return False; }
    }
    return True;
}

def contracts_in_chain(g: CallGraph, chain: list[str]) -> list[str] {
    out: list[str] = [];
    seen: dict[str, bool] = {};
    for fid in chain {
        fn = g.funcs.get(fid, None);
        if fn is None { continue; }
        if fn.contract not in seen {
            seen[fn.contract] = True;
            out.append(fn.contract);
        }
    }
    return out;
}
test "cross contract reentrancy chain" {
    g = load_call_graph(
        [
            ("A.deposit", "A"), ("B.withdraw", "B"), ("A.callback", "A"), ("C.route", "C")
        ],
        [
            ("A.deposit", "B.withdraw"), ("B.withdraw", "C.route"), ("C.route", "A.callback")
        ],
        ["A.deposit", "A.callback"],
    );
    hits = reentrant_chains(g, "A.deposit", 3);
    assert "A.callback" in hits;
    assert cross_contract_hops(g, "A.deposit", 3) == [
        "A.callback", "B.withdraw", "C.route"
    ];
}
