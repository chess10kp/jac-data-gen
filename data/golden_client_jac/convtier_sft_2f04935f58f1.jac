node Spot { has name: str; has lvl: int = -1; }

walker DepthCounter {
    has limit: int;
    has seen: int = 0;
    can tally with Spot entry {
        self.seen += 1;
        if here.lvl >= self.limit { return; }
        for nb in [-->(?lvl == -1)] {
            nb.lvl = here.lvl + 1;
            visit nb;
        }
    }
}

def count_within_depth(spec: dict) -> int {
    adj: dict = dict(spec["adj"]);
    union: dict = {};
    for (src, outs) in adj.items() {
        union[src] = 1;
        for dst in outs { union[dst] = 1; }
    }
    spots: dict = {};
    for nm in union.keys() { spots[nm] = Spot(name=str(nm)); }
    for (src, outs) in adj.items() { for dst in outs { spots[src] ++> spots[dst]; } }
    origin = spots[spec["start"]];
    origin.lvl = 0;
    w = origin spawn DepthCounter(limit=int(spec["depth"]));
    return w.seen;
}

with entry {
    print(count_within_depth({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': ['e'], 'e': []}, 'start': 'a', 'depth': 1}));
}
