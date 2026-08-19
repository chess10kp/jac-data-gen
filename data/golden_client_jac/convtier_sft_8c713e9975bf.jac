node Beacon { has name: str; has lit: bool; has scouted: bool = False; has stamp: int = -1; }

walker Scout {
    has targets: list = [];
    can look with Beacon entry {
        if not here.scouted {
            here.scouted = True;
            if here.lit { self.targets.append(here.name); }
            visit [-->];
        }
    }
}

walker ReachCount {
    has run: int;
    has count: int = 0;
    can roam with Beacon entry {
        if here.stamp != self.run {
            here.stamp = self.run;
            self.count += 1;
            visit [-->];
        }
    }
}

def flagged_reach_total(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); flags: dict = dict(spec["flags"]);
    beacons: dict = {};
    for nm in adj.keys() { beacons[nm] = Beacon(name=str(nm), lit=bool(flags[nm])); }
    for (a, bs) in adj.items() { for b in bs { beacons[a] ++> beacons[b]; } }
    scout = beacons[str(spec["start"])] spawn Scout();
    targets: list = list(scout.targets);
    targets.sort();
    total: int = 0;
    run: int = 0;
    for t in targets {
        total += (beacons[t] spawn ReachCount(run=run)).count;
        run += 1;
    }
    return total;
}

with entry {
    print(flagged_reach_total({'adj': {'s': ['a', 'b'], 'a': ['c'], 'b': [], 'c': []}, 'flags': {'s': False, 'a': True, 'b': True, 'c': False}, 'start': 's'}));
}
