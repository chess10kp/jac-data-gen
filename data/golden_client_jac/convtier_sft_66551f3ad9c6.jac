node Beacon { has name: str; has lit: bool; has depth: int = -1; }

walker BeaconSeek {
    has hits: list = [];
    has label: str = "dark";
    can launch with Root entry {
        for g in [-->][?:Beacon] { if g.depth == -1 { g.depth = 1; } }
        visit [-->][?:Beacon];
    }
    can seek with Beacon entry {
        if here.lit { self.hits.append((here.depth, here.name)); }
        for nxt in [-->][?:Beacon] {
            if nxt.depth == -1 { nxt.depth = here.depth + 1; visit nxt; }
        }
    }
    can settle with exit {
        if self.hits {
            self.hits.sort();
            self.label = self.hits[0][1] + "@" + str(self.hits[0][0]);
        }
    }
}

def nearest_beacon(spec: dict) -> str {
    for old in [root -->] { root del --> old; }
    beacons: dict = {};
    names: list = list(spec["gateways"]) + list(spec["links"].keys());
    for ts in spec["links"].values() { names += list(ts); }
    for nm in names {
        if nm not in beacons {
            beacons[nm] = Beacon(name=str(nm), lit=(nm in spec["lit"]));
        }
    }
    for g in list(spec["gateways"]) { root ++> beacons[g]; }
    for (s, ts) in spec["links"].items() {
        for t in list(ts) { beacons[s] ++> beacons[t]; }
    }
    return (root spawn BeaconSeek()).label;
}

with entry {
    print(nearest_beacon({'gateways': ['a', 'b'], 'links': {'a': ['c'], 'b': ['d']}, 'lit': ['c', 'd']}));
}
