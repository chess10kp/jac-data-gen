node Beacon { has bid: str; has lit: bool; has span: int = -1; }

walker Radar {
    has best: int = -1;
    can sweep with Beacon entry {
        if here.lit { self.best = here.span; disengage; }
        for nb in [-->(?span == -1)] {
            nb.span = here.span + 1;
            visit nb;
        }
    }
}

def nearest_flagged(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); glow: list = list(spec["lit"]);
    beacons: dict = {nm: Beacon(bid=str(nm), lit=(nm in glow)) for nm in adj.keys()};
    for (s, ts) in adj.items() { for t in list(ts) { beacons[s] ++> beacons[t]; } }
    beacons[spec["start"]].span = 0;
    w = Radar() spawn beacons[spec["start"]];
    return w.best;
}

with entry {
    print(nearest_flagged({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': [], 'd': []}, 'lit': ['d'], 'start': 'a'}));
}
