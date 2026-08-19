node Bough { has sap: int; has summed: bool = False; has gathered: bool = False; }

walker TotalScan {
    has total: int = 0;
    can add with Bough entry {
        if not here.summed {
            here.summed = True;
            self.total += here.sap;
            visit [-->];
        }
    }
}

walker LeafGather {
    has leaves: list = [];
    can pick with Bough entry {
        if not here.gathered {
            here.gathered = True;
            if len([-->]) == 0 { self.leaves.append(here.sap); }
            visit [-->];
        }
    }
}

def leaves_to_half(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); vals: dict = dict(spec["vals"]);
    wood: dict = {};
    for nm in adj.keys() { wood[nm] = Bough(sap=int(vals[nm])); }
    for (a, bs) in adj.items() { for b in bs { wood[a] ++> wood[b]; } }
    base = wood[str(spec["start"])];
    scan = base spawn TotalScan();
    gather = base spawn LeafGather();
    picks: list = list(gather.leaves);
    picks.sort();
    picks.reverse();
    got: int = 0;
    used: int = 0;
    for v in picks {
        if got * 2 >= scan.total { break; }
        got += v;
        used += 1;
    }
    if got * 2 >= scan.total { return used; }
    return -1;
}

with entry {
    print(leaves_to_half({'adj': {'a': ['b', 'c'], 'b': [], 'c': []}, 'vals': {'a': 2, 'b': 5, 'c': 3}, 'start': 'a'}));
}
