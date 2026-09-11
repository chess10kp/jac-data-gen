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


test "lineage walks the full ancestry" {
    F = [
        {"id": "f1", "cluster": 7, "weight": 10, "parent_ids": []},
        {"id": "f2", "cluster": 7, "weight": 4, "parent_ids": []},
        {"id": "s1", "cluster": 7, "weight": 6, "parent_ids": ["f1", "f2"]},
        {"id": "f3", "cluster": 12, "weight": 3, "parent_ids": []},
        {"id": "s2", "cluster": 12, "weight": 8, "parent_ids": ["s1", "f3"]},
        {"id": "s3", "cluster": 12, "weight": 5, "parent_ids": ["s2"]},
    ];
    assert lineage(F, "s3") == ["f1", "f2", "f3", "s1", "s2"];
    assert lineage(F, "s2") == ["f1", "f2", "f3", "s1"];
    assert lineage(F, "f1") == [];
}

test "lineage depth cap excludes deeper ancestors" {
    F = [
        {"id": "f1", "cluster": 7, "weight": 10, "parent_ids": []},
        {"id": "f2", "cluster": 7, "weight": 4, "parent_ids": []},
        {"id": "s1", "cluster": 7, "weight": 6, "parent_ids": ["f1", "f2"]},
        {"id": "f3", "cluster": 12, "weight": 3, "parent_ids": []},
        {"id": "s2", "cluster": 12, "weight": 8, "parent_ids": ["s1", "f3"]},
        {"id": "s3", "cluster": 12, "weight": 5, "parent_ids": ["s2"]},
    ];
    assert lineage(F, "s3", max_depth=0) == [];
    assert lineage(F, "s3", max_depth=1) == ["s2"];
    assert lineage(F, "s3", max_depth=2) == ["f3", "s1", "s2"];
    assert lineage(F, "s3", max_depth=3) == ["f1", "f2", "f3", "s1", "s2"];
}

test "adversarial-order diamond counts the short chain" {
    D = [
        {"id": "x3", "cluster": 1, "weight": 1, "parent_ids": []},
        {"id": "x1", "cluster": 1, "weight": 1, "parent_ids": ["x3"]},
        {"id": "x0", "cluster": 1, "weight": 1, "parent_ids": ["x1", "x3"]},
    ];
    assert lineage(D, "x0", max_depth=1) == ["x1", "x3"];
    assert lineage(D, "x0") == ["x1", "x3"];

    D2 = [
        {"id": "yM", "cluster": 1, "weight": 1, "parent_ids": []},
        {"id": "yD", "cluster": 1, "weight": 1, "parent_ids": ["yM"]},
        {"id": "yC", "cluster": 1, "weight": 1, "parent_ids": ["yD"]},
        {"id": "yB", "cluster": 1, "weight": 1, "parent_ids": ["yC"]},
        {"id": "yA", "cluster": 1, "weight": 1, "parent_ids": ["yM"]},
        {"id": "y0", "cluster": 1, "weight": 1, "parent_ids": ["yB", "yA"]},
    ];
    assert lineage(D2, "y0", max_depth=2) == ["yA", "yB", "yC", "yM"];
    assert lineage(D2, "y0", max_depth=3) == ["yA", "yB", "yC", "yD", "yM"];
    assert lineage(D2, "y0") == ["yA", "yB", "yC", "yD", "yM"];
}

test "parent loop terminates without losing ancestors" {
    C = [
        {"id": "c2", "cluster": 1, "weight": 1, "parent_ids": ["c1"]},
        {"id": "c1", "cluster": 1, "weight": 1, "parent_ids": ["c2"]},
        {"id": "c0", "cluster": 1, "weight": 1, "parent_ids": ["c1"]},
    ];
    assert lineage(C, "c0") == ["c1", "c2"];
}

test "unknown parents skipped, unknown root raises KeyError" {
    G = [
        {"id": "g1", "cluster": 1, "weight": 1, "parent_ids": ["ghost", "g0"]},
        {"id": "g0", "cluster": 1, "weight": 1, "parent_ids": []},
    ];
    assert lineage(G, "g1") == ["g0"];
    try {
        lineage(G, "ghost");
        assert False, "expected KeyError";
    } except KeyError { assert True; }
    try {
        synthesis_depth(G, "ghost");
        assert False, "expected KeyError";
    } except KeyError { assert True; }
    try {
        priority(G, "ghost");
        assert False, "expected KeyError";
    } except KeyError { assert True; }
}

test "synthesis depth is the longest root chain" {
    F = [
        {"id": "f1", "cluster": 7, "weight": 10, "parent_ids": []},
        {"id": "f2", "cluster": 7, "weight": 4, "parent_ids": []},
        {"id": "s1", "cluster": 7, "weight": 6, "parent_ids": ["f1", "f2"]},
        {"id": "f3", "cluster": 12, "weight": 3, "parent_ids": []},
        {"id": "s2", "cluster": 12, "weight": 8, "parent_ids": ["s1", "f3"]},
        {"id": "s3", "cluster": 12, "weight": 5, "parent_ids": ["s2"]},
    ];
    assert synthesis_depth(F, "f1") == 0;
    assert synthesis_depth(F, "s1") == 1;
    assert synthesis_depth(F, "s2") == 2;
    assert synthesis_depth(F, "s3") == 3;

    Z = [
        {"id": "t", "cluster": 1, "weight": 1, "parent_ids": []},
        {"id": "a", "cluster": 1, "weight": 1, "parent_ids": ["t"]},
        {"id": "b", "cluster": 1, "weight": 1, "parent_ids": ["t"]},
        {"id": "z", "cluster": 1, "weight": 1, "parent_ids": ["a", "b"]},
    ];
    assert synthesis_depth(Z, "z") == 2;

    W = [
        {"id": "q", "cluster": 1, "weight": 1, "parent_ids": []},
        {"id": "v", "cluster": 1, "weight": 1, "parent_ids": ["q"]},
        {"id": "u", "cluster": 1, "weight": 1, "parent_ids": ["v"]},
        {"id": "ps", "cluster": 1, "weight": 1, "parent_ids": ["q"]},
        {"id": "w", "cluster": 1, "weight": 1, "parent_ids": ["u", "ps"]},
    ];
    assert synthesis_depth(W, "w") == 3;
}

test "priority boosts only at depth >= 2" {
    F = [
        {"id": "f1", "cluster": 7, "weight": 10, "parent_ids": []},
        {"id": "f2", "cluster": 7, "weight": 4, "parent_ids": []},
        {"id": "s1", "cluster": 7, "weight": 6, "parent_ids": ["f1", "f2"]},
        {"id": "f3", "cluster": 12, "weight": 3, "parent_ids": []},
        {"id": "s2", "cluster": 12, "weight": 8, "parent_ids": ["s1", "f3"]},
        {"id": "s3", "cluster": 12, "weight": 5, "parent_ids": ["s2"]},
    ];
    assert priority(F, "f3") == 3;
    assert priority(F, "s1") == 6;
    assert priority(F, "s2") == 13;
    assert priority(F, "s3") == 10;
}
