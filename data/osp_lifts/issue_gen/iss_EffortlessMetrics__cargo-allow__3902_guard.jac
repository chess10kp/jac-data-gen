"""EffortlessMetrics/cargo-allow#3902 — candidate + hidden guards."""

obj EvidenceStore {
    has stamp: int = 0;
}

node Claim {
    has name: str;
}

edge Requires {}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for c in [-->][?:Claim] {
            if c.name == self.start {
                visit [c];
            }
        }
    }

    can step with Claim entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name != self.start {
            self.reached.append(here.name);
        }
        visit [->:Requires:->][?:Claim];
    }

    can finish with Root exit {
        report self.reached;
    }
}

def _wire(claims: list[str], requires: list[tuple[str, str]]) {
    mp: dict[str, Claim] = {};
    for nm in claims {
        if nm not in mp {
            c = Claim(name=nm);
            root ++> c;
            mp[nm] = c;
        }
    }
    for (dst, src) in requires {
        d = mp.get(dst, None);
        s = mp.get(src, None);
        if d is not None and s is not None {
            dup = False;
            for up in [d ->:Requires:->][?:Claim] {
                if up.name == src {
                    dup = True;
                }
            }
            if not dup {
                d +>:Requires:+> s;
            }
        }
    }
}

def _claim(name: str) -> Claim | None {
    for c in [-->][?:Claim] {
        if c.name == name {
            return c;
        }
    }
    return None;
}

def load_evidence(
    claims: list[str],
    requires: list[tuple[str, str]],
) -> EvidenceStore {
    _wire(claims, requires);
    return EvidenceStore(stamp=1);
}

def evidence_waves(g: EvidenceStore) -> list[list[str]] | None {
    _ = g;
    indeg: dict[str, int] = {};
    for c in [-->][?:Claim] {
        indeg[c.name] = len([c ->:Requires:->][?:Claim]);
    }
    waves: list[list[str]] = [];
    ready = sorted([nm for (nm, d) in indeg.items() if d == 0]);
    while ready {
        waves.append(ready);
        nxt: list[str] = [];
        for nm in ready {
            cur = _claim(nm);
            if cur is None {
                continue;
            }
            for dep in [cur <-:Requires:<-][?:Claim] {
                indeg[dep.name] -= 1;
                if indeg[dep.name] == 0 {
                    nxt.append(dep.name);
                }
            }
        }
        ready = sorted(nxt);
    }
    total = 0;
    for w in waves {
        total += len(w);
    }
    return waves if total == len(indeg) else None;
}

def upstream_closure(g: EvidenceStore, claim: str) -> list[str] {
    _ = g;
    if _claim(claim) is None {
        return [];
    }
    w = root spawn UpstreamWalk(start=claim, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

test "evidence waves and upstream closure" {
    g = load_evidence(
        ["rust_edition", "resolver3", "msrv_proof", "lockfile_delta", "api_compat"],
        [
            ("resolver3", "rust_edition"),
            ("msrv_proof", "rust_edition"),
            ("lockfile_delta", "resolver3"),
            ("api_compat", "lockfile_delta"),
            ("api_compat", "msrv_proof"),
        ],
    );
    assert evidence_waves(g) == [
        ["rust_edition"],
        ["msrv_proof", "resolver3"],
        ["lockfile_delta"],
        ["api_compat"],
    ];
    assert upstream_closure(g, "api_compat") == [
        "lockfile_delta",
        "msrv_proof",
        "resolver3",
        "rust_edition",
    ];
}

test "cycle returns none waves" {
    g = load_evidence(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert evidence_waves(g) is None;
}

test "unknown claim tolerant" {
    g = load_evidence(["only"], []);
    assert upstream_closure(g, "missing") == [];
}

test "adversarial diamond upstream once per claim" {
    # Edge insertion forces shared base revisit before deeper first-visits settle.
    g = load_evidence(
        ["top", "left", "right", "base", "leaf"],
        [
            ("top", "right"),
            ("base", "leaf"),
            ("left", "base"),
            ("top", "left"),
            ("right", "base"),
        ],
    );
    assert upstream_closure(g, "top") == ["base", "leaf", "left", "right"];
}
