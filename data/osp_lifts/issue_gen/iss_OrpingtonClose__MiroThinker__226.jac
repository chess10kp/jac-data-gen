"""Flock SYNTHESIZE lineage, lifted to OSP.

Findings become Finding nodes; a synthesis's ``parent_ids`` entries become
DerivesFrom edges (synthesis -> source finding), so the recursive lineage
walk the issue asks for is a walker hop over typed edges instead of
recursive descent with a depths dict: ``lineage`` is a shortest-chain
relaxation walk capped by the depth limit, ``synthesis_depth`` a
longest-chain walk over the same edges, and the priority boost composes
on top. The claim maps ARE the cycle policy -- parent loops terminate
without losing ancestors -- and the depth cap survives as domain policy.
Ref: OrpingtonClose/MiroThinker#226
"""
node Finding {
    has fid: str;
    has weight: int;
}
edge DerivesFrom {}  # synthesis -> its source finding

glob MAX_LINEAGE_DEPTH: int = 10;
glob DEPTH_BOOST: int = 5;
glob DEPTH_BOOST_THRESHOLD: int = 2;

"""Loader handle: id-string parameters resolve through this lookup map."""
obj Flock {
    has findings: dict[str, Finding];

    def resolve(fid: str) -> Finding | None {
        return self.findings.get(fid);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def load_flock(findings: list) -> Flock {
    fl = Flock(findings={});
    for rec in findings {
        fid = str(rec["id"]);
        f = Finding(fid=fid, weight=int(rec["weight"]));
        root ++> f;
        fl.findings[fid] = f;
    }
    for rec in findings {
        child = fl.resolve(str(rec["id"]));
        if child is None {
            continue;
        }
        plist = list(rec["parent_ids"]);
        for pid in plist {
            src = fl.resolve(str(pid));
            if src is None {
                continue;  # unknown parent refs are skipped, as in the store
            }
            child +>:DerivesFrom:+> src;
        }
    }
    return fl;
}

walker LineageRelax {
    # Cycle policy: claim map keyed by finding id (jac walkers do not
    # dedupe). A non-improving revisit skips; a strictly shallower arrival
    # re-expands, so the map ends holding each ancestor's shortest hop
    # count -- the depth-bounded lineage of the issue's recursive CTE.
    has best: dict[str, int] = {};
    has hops: int = 0;
    has cap: int = 10;

    can step with Finding entry {
        if here.fid in self.best and self.hops >= self.best[here.fid] {
            skip;
        }
        self.best[here.fid] = self.hops;
        if self.hops < self.cap {
            for src in [here->:DerivesFrom:->] {
                src spawn LineageRelax(best=self.best, hops=self.hops + 1, cap=self.cap);
            }
        }
    }
}

walker ChainDepth {
    # Longest root chain: max-arrival claim map. A revisit that is not
    # strictly deeper skips; a deeper arrival re-expands. The parent DAG
    # is acyclic by construction, so the walk terminates.
    has best: dict[str, int] = {};
    has hops: int = 0;

    can step with Finding entry {
        if here.fid in self.best and self.hops <= self.best[here.fid] {
            skip;
        }
        self.best[here.fid] = self.hops;
        for src in [here->:DerivesFrom:->] {
            src spawn ChainDepth(best=self.best, hops=self.hops + 1);
        }
    }
}

"""Ancestor ids of ``fid`` within ``max_depth`` parent hops, sorted."""
def lineage(findings: list, fid: str, max_depth: int = MAX_LINEAGE_DEPTH) -> list[str] {
    fl = load_flock(findings);
    start = fl.resolve(fid);
    if start is None {
        raise KeyError(fid);
    }
    w = start spawn LineageRelax(best={}, hops=0, cap=max_depth);
    out: list[str] = [];
    for k in w.best.keys() {
        if k != fid and w.best[k] <= max_depth {
            out.append(k);
        }
    }
    return sorted(out);
}

"""How many synthesis layers deep ``fid`` sits: longest root chain."""
def synthesis_depth(findings: list, fid: str) -> int {
    fl = load_flock(findings);
    start = fl.resolve(fid);
    if start is None {
        raise KeyError(fid);
    }
    w = start spawn ChainDepth(best={}, hops=0);
    deepest = 0;
    for k in w.best.keys() {
        if w.best[k] > deepest {
            deepest = w.best[k];
        }
    }
    return deepest;
}

"""Base weight of ``fid``, boosted once synthesis depth >= 2."""
def priority(findings: list, fid: str) -> int {
    fl = load_flock(findings);
    f = fl.resolve(fid);
    if f is None {
        raise KeyError(fid);
    }
    base = f.weight;
    if synthesis_depth(findings, fid) >= DEPTH_BOOST_THRESHOLD {
        base += DEPTH_BOOST;
    }
    return base;
}
