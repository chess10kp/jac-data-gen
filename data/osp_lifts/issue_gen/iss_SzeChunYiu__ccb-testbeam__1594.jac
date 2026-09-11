"""SzeChunYiu/ccb-testbeam#1594 — Numerical audit claim dependency cascade quarantine."""

node Claim {
    has name: str;
    has status: str = "pending";
}

edge ChildOf {}

obj AuditGraph {
    has claims: dict[str, Claim] = {};

    def add_claim(name: str, parent: str | None = None) {
        if parent is not None and self.claims.get(parent, None) is None {
            raise KeyError("unknown upstream claim");
        }
        n = Claim(name=name);
        root ++> n;
        self.claims[name] = n;
        if parent is not None {
            p = self.claims.get(parent, None);
            if p is not None { p +>:ChildOf:+> n; }
        }
    }

    def mark_failed(claim_id: str) -> list[str] {
        start = self.claims.get(claim_id, None);
        if start is None { raise KeyError("unknown claim"); }
        w = start spawn SubtreeCollect(claimed={}, found=[]);
        changed: list[str] = [];
        for cid in w.found {
            n = self.claims.get(cid, None);
            if n is None or n.status == "quarantined" { continue; }
            n.status = "quarantined";
            changed.append(cid);
        }
        return sorted(changed);
    }

    def active_claims() -> list[str] {
        out: list[str] = [];
        for k in self.claims.keys() {
            n = self.claims.get(k, None);
            if n is not None and n.status != "quarantined" { out.append(k); }
        }
        return sorted(out);
    }
}

walker SubtreeCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Claim entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        for ch in [here ->:ChildOf:->][?:Claim] {
            visit [ch];
        }
    }
}

def load_audit_graph(claims: list[tuple[str, str | None]]) -> AuditGraph {
    g = AuditGraph();
    for (name, parent) in claims { g.add_claim(name, parent); }
    return g;
}

def mark_failed(store: AuditGraph, claim_id: str) -> list[str] {
    return store.mark_failed(claim_id);
}

def active_claims(store: AuditGraph) -> list[str] {
    return store.active_claims();
}

def upstream_chain(store: AuditGraph, claim: str) -> list[str] {
    nd = store.claims.get(claim, None);
    if nd is None { return []; }
    chain: list[str] = [];
    cur: Claim | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.name in seen { break; }
        seen[cur.name] = True;
        chain.append(cur.name);
        parent: Claim | None = None;
        for p in [cur <-:ChildOf:<-][?:Claim] {
            parent = p;
            break;
        }
        cur = parent;
    }
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}
