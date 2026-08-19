edge Road {}
edge Rail {}
node Yard { has name: str; has by_road: bool = False; has by_rail: bool = False; }

walker RoadMark {
    can step with Yard entry {
        if not here.by_road {
            here.by_road = True;
            visit [->:Road:->];
        }
    }
}

walker RailMark {
    can step with Yard entry {
        if not here.by_rail {
            here.by_rail = True;
            visit [->:Rail:->];
        }
    }
}

def shared_reach_count(spec: dict) -> int {
    reg: dict = {};
    reg[spec["start"]] = Yard(name=spec["start"]);
    for pr in spec["roads"] { for nm in pr { if nm not in reg { reg[nm] = Yard(name=nm); } } }
    for pr in spec["rails"] { for nm in pr { if nm not in reg { reg[nm] = Yard(name=nm); } } }
    for pr in spec["roads"] { reg[pr[0]] +>:Road:+> reg[pr[1]]; }
    for pr in spec["rails"] { reg[pr[0]] +>:Rail:+> reg[pr[1]]; }
    wa = reg[spec["start"]] spawn RoadMark();
    wb = reg[spec["start"]] spawn RailMark();
    both: int = 0;
    for nd in reg.values() { if nd.by_road and nd.by_rail { both += 1; } }
    return both;
}

with entry {
    print(shared_reach_count({'roads': [['a', 'b'], ['b', 'c']], 'rails': [['a', 'b'], ['a', 'c']], 'start': 'a'}));
}
