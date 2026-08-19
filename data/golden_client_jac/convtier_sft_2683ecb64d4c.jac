edge Road {}
edge Rail {}
node Town { has name: str; has seen: bool = False; }

walker RoadScout {
    has count: int = 0;
    can step with Town entry {
        if not here.seen {
            here.seen = True;
            self.count += 1;
            visit [->:Road:->];
        }
    }
}

def count_road_reachable(spec: dict) -> int {
    reg: dict = {};
    reg[spec["start"]] = Town(name=spec["start"]);
    for pr in spec["roads"] { for nm in pr { if nm not in reg { reg[nm] = Town(name=nm); } } }
    for pr in spec["rails"] { for nm in pr { if nm not in reg { reg[nm] = Town(name=nm); } } }
    for pr in spec["roads"] { reg[pr[0]] +>:Road:+> reg[pr[1]]; }
    for pr in spec["rails"] { reg[pr[0]] +>:Rail:+> reg[pr[1]]; }
    wk = reg[spec["start"]] spawn RoadScout();
    return wk.count;
}

with entry {
    print(count_road_reachable({'roads': [['a', 'b'], ['b', 'c']], 'rails': [['a', 'x'], ['x', 'y']], 'start': 'a'}));
}
