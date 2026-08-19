node Site { has hit_a: bool = False; has hit_b: bool = False; }

walker MarkA {
    can mark with Site entry {
        if not here.hit_a {
            here.hit_a = True;
            visit [-->];
        }
    }
}

walker MarkB {
    can mark with Site entry {
        if not here.hit_b {
            here.hit_b = True;
            visit [-->];
        }
    }
}

def overlap_report(spec: dict) -> str {
    adj: dict = dict(spec["adj"]);
    sites: dict = {};
    for nm in adj.keys() { sites[nm] = Site(); }
    for (a, bs) in adj.items() { for b in bs { sites[a] ++> sites[b]; } }
    wa = sites[str(spec["a"])] spawn MarkA();
    wb = sites[str(spec["b"])] spawn MarkB();
    both: int = 0;
    lone: int = 0;
    for nm in sites.keys() {
        s = sites[nm];
        if s.hit_a and s.hit_b { both += 1; }
        elif s.hit_a or s.hit_b { lone += 1; }
    }
    return "both=" + str(both) + ";only=" + str(lone);
}

with entry {
    print(overlap_report({'adj': {'a': ['c'], 'b': ['c'], 'c': ['d'], 'd': []}, 'a': 'a', 'b': 'b'}));
}
