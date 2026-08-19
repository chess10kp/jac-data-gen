node Hub { has name: str; has portal: bool; has scouted: bool = False; }

walker Scout {
    has found: list = [];
    can look with Hub entry {
        if not here.scouted {
            here.scouted = True;
            if here.portal { self.found.append(here.name); }
            visit [-->];
        }
    }
}

walker FanCount {
    has stage: int = 0;
    has fan: int = 0;
    can look with Hub entry {
        if self.stage == 0 {
            self.stage = 1;
            visit [-->];
        } else {
            self.fan += 1;
        }
    }
}

def portal_fanout_total(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); flags: dict = dict(spec["flags"]);
    hubs: dict = {};
    for nm in adj.keys() { hubs[nm] = Hub(name=str(nm), portal=bool(flags[nm])); }
    for (a, bs) in adj.items() { for b in bs { hubs[a] ++> hubs[b]; } }
    scout = hubs[str(spec["start"])] spawn Scout();
    total: int = 0;
    for nm in sorted(scout.found) { total += (hubs[nm] spawn FanCount()).fan; }
    return total;
}

with entry {
    print(portal_fanout_total({'adj': {'s': ['p', 'q'], 'p': ['x', 'y'], 'q': [], 'x': [], 'y': []}, 'flags': {'s': False, 'p': True, 'q': True, 'x': False, 'y': False}, 'start': 's'}));
}
