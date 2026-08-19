node Twig { has name: str; has size: int; has passed: bool = False; }

walker LeafScan {
    has hits: int = 0;
    can inspect with Twig entry {
        if not here.passed {
            here.passed = True;
            if len([-->]) == 0 and here.size % 2 == 0 { self.hits += 1; }
            visit [-->];
        }
    }
}

def count_even_leaves(spec: dict) -> int {
    adj: dict = spec["adj"]; vals: dict = spec["vals"];
    built: dict = {};
    for (u, vs) in adj.items() {
        if u not in built { built[u] = Twig(name=u, size=vals[u]); }
        for v in vs { if v not in built { built[v] = Twig(name=v, size=vals[v]); } }
    }
    for (u, vs) in adj.items() { for v in vs { built[u] ++> built[v]; } }
    wk = built[spec["start"]] spawn LeafScan();
    return wk.hits;
}

with entry {
    print(count_even_leaves({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['e'], 'd': [], 'e': []}, 'vals': {'a': 2, 'b': 3, 'c': 5, 'd': 4, 'e': 7}, 'start': 'a'}));
}
