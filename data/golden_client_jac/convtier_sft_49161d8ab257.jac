node Station { has name: str; has depth: int = -1; }

walker HopMeter {
    has target: str;
    has best: int = -1;
    can launch with Root entry {
        for g in [-->][?:Station] { if g.depth == -1 { g.depth = 1; } }
        visit [-->][?:Station];
    }
    can hop with Station entry {
        if here.name == self.target and (self.best == -1 or here.depth < self.best) {
            self.best = here.depth;
        }
        for nxt in [-->][?:Station] {
            if nxt.depth == -1 { nxt.depth = here.depth + 1; visit nxt; }
        }
    }
}

def hops_from_root(spec: dict) -> int {
    for old in [root -->] { root del --> old; }
    stations: dict = {};
    names: list = list(spec["gateways"]) + list(spec["links"].keys());
    for ts in spec["links"].values() { names += list(ts); }
    for nm in names {
        if nm not in stations { stations[nm] = Station(name=str(nm)); }
    }
    for g in list(spec["gateways"]) { root ++> stations[g]; }
    for (s, ts) in spec["links"].items() {
        for t in list(ts) { stations[s] ++> stations[t]; }
    }
    return (root spawn HopMeter(target=str(spec["target"]))).best;
}

with entry {
    print(hops_from_root({'gateways': ['a', 'b'], 'links': {'a': ['c'], 'c': ['d'], 'b': ['d']}, 'target': 'd'}));
}
