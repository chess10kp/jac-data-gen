node Ring { has val: int; has depth: int = -1; has stamped: bool = False; has scanned: bool = False; }

walker DepthStamp {
    can roam with Ring entry {
        if not here.stamped {
            here.stamped = True;
            for nxt in [-->] {
                if nxt.depth == -1 { nxt.depth = here.depth + 1; }
            }
            visit [-->];
        }
    }
}

walker ParityGap {
    has gap: int = 0;
    can scan with Ring entry {
        if not here.scanned {
            here.scanned = True;
            if here.depth % 2 == 0 { self.gap += here.val; }
            else { self.gap -= here.val; }
            visit [-->];
        }
    }
}

def even_odd_depth_gap(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); vals: dict = dict(spec["vals"]);
    rings: dict = {};
    for nm in adj.keys() { rings[nm] = Ring(val=int(vals[nm])); }
    for (a, bs) in adj.items() { for b in bs { rings[a] ++> rings[b]; } }
    base = rings[str(spec["start"])];
    base.depth = 0;
    stamper = base spawn DepthStamp();
    return (base spawn ParityGap()).gap;
}

with entry {
    print(even_odd_depth_gap({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': [], 'd': []}, 'vals': {'a': 10, 'b': 3, 'c': 4, 'd': 6}, 'start': 'a'}));
}
