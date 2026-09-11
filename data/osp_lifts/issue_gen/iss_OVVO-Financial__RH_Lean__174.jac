"""OVVO-Financial/RH_Lean#174 — Theorem dependency chain for RH formalization route."""

node Theorem {
    has name: str;
}

edge PrereqOf {}

obj TheoremGraph {
    has theorems: dict[str, Theorem] = {};
}

walker Downstream {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Theorem entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        for dep in [here <-:PrereqOf:<-][?:Theorem] {
            visit [dep];
        }
    }
}

def load_theorems(stmts: list[tuple[str, str | None]]) -> TheoremGraph {
    g = TheoremGraph();
    for (name, parent) in stmts {
        if parent is not None and g.theorems.get(parent, None) is None {
            raise KeyError("unknown prerequisite");
        }
        nd = Theorem(name=name);
        root ++> nd;
        g.theorems[name] = nd;
        if parent is not None {
            p = g.theorems.get(parent, None);
            if p is not None { nd +>:PrereqOf:+> p; }
        }
    }
    return g;
}

def proof_chain(store: TheoremGraph, target: str) -> list[str] {
    nd = store.theorems.get(target, None);
    if nd is None { return []; }
    chain: list[str] = [];
    cur: Theorem | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.name in seen { break; }
        seen[cur.name] = True;
        chain.append(cur.name);
        parent: Theorem | None = None;
        for p in [cur ->:PrereqOf:->][?:Theorem] {
            parent = p;
            break;
        }
        cur = parent;
    }
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

def downstream_theorems(store: TheoremGraph, `root: str) -> list[str] {
    nd = store.theorems.get(`root, None);
    if nd is None { return []; }
    w = nd spawn Downstream(claimed={}, found=[]);
    return sorted(w.found);
}
