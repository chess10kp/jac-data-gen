node Spire { has name: str; has val: int; has depth: int = -1; has seen: bool = False; has stamped: bool = False; has scanned: bool = False; }

walker PeakSeek {
    has best_name: str = "";
    has best_val: int = 0;
    can seek with Spire entry {
        if not here.seen {
            here.seen = True;
            if self.best_name == "" or here.val > self.best_val or (here.val == self.best_val and here.name < self.best_name) {
                self.best_name = here.name;
                self.best_val = here.val;
            }
            visit [-->];
        }
    }
}

walker DepthStamp {
    can roam with Spire entry {
        if not here.stamped {
            here.stamped = True;
            for nxt in [-->] {
                if nxt.depth == -1 { nxt.depth = here.depth + 1; }
            }
            visit [-->];
        }
    }
}

walker RadiusTally {
    has radius: int;
    has count: int = 0;
    can scan with Spire entry {
        if not here.scanned {
            here.scanned = True;
            if here.depth <= self.radius { self.count += 1; }
            visit [-->];
        }
    }
}

def peak_radius_count(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); vals: dict = dict(spec["vals"]);
    spires: dict = {};
    for nm in adj.keys() { spires[nm] = Spire(name=str(nm), val=int(vals[nm])); }
    for (a, bs) in adj.items() { for b in bs { spires[a] ++> spires[b]; } }
    seeker = spires[str(spec["start"])] spawn PeakSeek();
    peak = spires[seeker.best_name];
    peak.depth = 0;
    stamper = peak spawn DepthStamp();
    return (peak spawn RadiusTally(radius=int(spec["radius"]))).count;
}

with entry {
    print(peak_radius_count({'adj': {'s': ['a', 'b'], 'a': ['c'], 'b': [], 'c': []}, 'vals': {'s': 1, 'a': 9, 'b': 2, 'c': 5}, 'start': 's', 'radius': 1}));
}
