node Floor { has name: str; has val: int; has lvl: int = -1; has swept: bool = False; }

walker Diver {
    has mark: int;
    has best: int = -1;
    can sink with Floor entry {
        if not here.swept {
            here.swept = True;
            if here.val > self.mark and here.lvl > self.best { self.best = here.lvl; }
            for nxt in [-->] { if nxt.lvl == -1 { nxt.lvl = here.lvl + 1; } }
            visit [-->];
        }
    }
}

def deepest_hit(spec: dict) -> int {
    adj: dict = spec["adj"]; vals: dict = spec["vals"];
    all_names: list = list(adj.keys());
    for ends in adj.values() { for e in ends { if e not in all_names { all_names.append(e); } } }
    floors: dict = {};
    for nm in all_names { floors[nm] = Floor(name=nm, val=vals[nm]); }
    for (src, ends) in adj.items() { for e in ends { floors[src] ++> floors[e]; } }
    floors[spec["start"]].lvl = 0;
    w = floors[spec["start"]] spawn Diver(mark=spec["mark"]);
    return w.best;
}

with entry {
    print(deepest_hit({'adj': {'a': ['b'], 'b': ['c'], 'c': ['d'], 'd': []}, 'vals': {'a': 1, 'b': 9, 'c': 2, 'd': 7}, 'start': 'a', 'mark': 5}));
}
