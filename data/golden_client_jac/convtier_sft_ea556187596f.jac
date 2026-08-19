node Depot { has stock: int; has hit: bool = False; has counted: bool = False; }

walker MarkReach {
    can mark with Depot entry {
        if not here.hit {
            here.hit = True;
            visit [-->];
        }
    }
}

walker SharedSum {
    has total: int = 0;
    can gather with Depot entry {
        if not here.counted {
            here.counted = True;
            if here.hit { self.total += here.stock; }
            visit [-->];
        }
    }
}

def shared_reach_sum(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); vals: dict = dict(spec["vals"]);
    depots: dict = {};
    for nm in vals.keys() { depots[nm] = Depot(stock=int(vals[nm])); }
    for (a, bs) in adj.items() { for b in bs { depots[a] ++> depots[b]; } }
    marker = depots[str(spec["a"])] spawn MarkReach();
    return (depots[str(spec["b"])] spawn SharedSum()).total;
}

with entry {
    print(shared_reach_sum({'adj': {'a': ['c', 'd'], 'b': ['d', 'e'], 'c': [], 'd': ['f'], 'e': [], 'f': []}, 'vals': {'a': 1, 'b': 1, 'c': 1, 'd': 2, 'e': 3, 'f': 4}, 'a': 'a', 'b': 'b'}));
}
