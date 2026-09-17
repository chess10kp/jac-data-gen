"""Reactive queries: dotnet/orleans#1883 — memoized queries with push updates."""

node Grain {
    has name: str;
    has version: int = 0;
    has memo: dict[str, int] = {};
}

edge Sub {
    has qid: str = "";
}

walker Propagate {
    has qid: str = "";
    has claimed: dict[str, bool] = {};
    can step with Grain entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        here.memo[self.qid] = here.version;
        for t in [here ->:Sub:->][?:Grain] {
            visit t;
        }
    }
}

def make_grain(name: str) -> Grain {
    g = Grain(name=name);
    root ++> g;
    return g;
}

def add_sub(a: Grain, b: Grain, qid: str) {
    a +>:Sub(qid=qid):+> b;
}

# Non-query mutation triggers conservative re-execution of qid downstream.
def recompute(src: Grain, qid: str) -> list[str] {
    src.version += 1;
    wk = Propagate(qid=qid, claimed={});
    src spawn wk;
    updated: list[str] = [];
    for k in sorted(wk.claimed.keys()) {
        updated.append(k);
    }
    return updated;
}

def get_memo(g: Grain, qid: str) -> int | None {
    if qid in g.memo.keys() {
        return g.memo[qid];
    }
    return None;
}

def subscribers(g: Grain) -> list[str] {
    out: list[str] = [];
    for t in [g ->:Sub:->][?:Grain] {
        out.append(t.name);
    }
    return sorted(out);
}

def network(names: list[str]) -> list[Grain] {
    gs: list[Grain] = [];
    for nm in names {
        gs.append(make_grain(nm));
    }
    return gs;
}
