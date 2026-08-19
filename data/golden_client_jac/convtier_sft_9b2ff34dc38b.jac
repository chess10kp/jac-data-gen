node Town { has name: str; has lit: bool = False; }

walker Lamplighter {
    can glow with Town entry {
        if not here.lit {
            here.lit = True;
            visit [-->];
        }
    }
}

def count_unreachable(spec: dict) -> int {
    adj: dict = dict(spec["adj"]);
    towns: dict = {};
    for (u, vs) in adj.items() {
        if u not in towns { towns[u] = Town(name=str(u)); }
        for v in vs {
            if v not in towns { towns[v] = Town(name=str(v)); }
            towns[u] ++> towns[v];
        }
    }
    towns[spec["start"]] spawn Lamplighter();
    dark: int = 0;
    for t in towns.values() {
        if not t.lit { dark += 1; }
    }
    return dark;
}

with entry {
    print(count_unreachable({'adj': {'a': ['b'], 'b': [], 'c': ['d'], 'd': ['c']}, 'start': 'a'}));
}
