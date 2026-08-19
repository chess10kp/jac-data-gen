edge Road {}
edge Rail {}
node Depot { has name: str; has seen_road: bool = False; has seen_rail: bool = False; }

walker RoadReach {
    has count: int = 0;
    can step with Depot entry {
        if not here.seen_road {
            here.seen_road = True;
            self.count += 1;
            visit [->:Road:->];
        }
    }
}

walker RailReach {
    has count: int = 0;
    can step with Depot entry {
        if not here.seen_rail {
            here.seen_rail = True;
            self.count += 1;
            visit [->:Rail:->];
        }
    }
}

def wider_network(spec: dict) -> str {
    reg: dict = {};
    reg[spec["start"]] = Depot(name=spec["start"]);
    for pr in spec["roads"] { for nm in pr { if nm not in reg { reg[nm] = Depot(name=nm); } } }
    for pr in spec["rails"] { for nm in pr { if nm not in reg { reg[nm] = Depot(name=nm); } } }
    for pr in spec["roads"] { reg[pr[0]] +>:Road:+> reg[pr[1]]; }
    for pr in spec["rails"] { reg[pr[0]] +>:Rail:+> reg[pr[1]]; }
    wr = reg[spec["start"]] spawn RoadReach();
    wl = reg[spec["start"]] spawn RailReach();
    if wr.count > wl.count { return "road"; }
    if wl.count > wr.count { return "rail"; }
    return "tie";
}

with entry {
    print(wider_network({'roads': [['a', 'b'], ['b', 'c']], 'rails': [['a', 'x']], 'start': 'a'}));
}
