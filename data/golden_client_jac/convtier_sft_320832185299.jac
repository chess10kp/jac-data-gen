node Way { has ident: str; has hops: int = -1; }

walker HopFinder {
    has goal: str;
    has dist: int = -1;
    can advance with Way entry {
        if here.ident == self.goal { self.dist = here.hops; disengage; }
        for nb in [-->] {
            if nb.hops == -1 { nb.hops = here.hops + 1; visit nb; }
        }
    }
}

def hops_to_target(spec: dict) -> int {
    ways: dict = {};
    for (s, ts) in dict(spec["adj"]).items() {
        if s not in ways { ways[s] = Way(ident=str(s)); }
        for t in list(ts) {
            if t not in ways { ways[t] = Way(ident=str(t)); }
            ways[s] ++> ways[t];
        }
    }
    ways[spec["start"]].hops = 0;
    w = HopFinder(goal=str(spec["target"])) spawn ways[spec["start"]];
    return w.dist;
}

with entry {
    print(hops_to_target({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'start': 'a', 'target': 'd'}));
}
