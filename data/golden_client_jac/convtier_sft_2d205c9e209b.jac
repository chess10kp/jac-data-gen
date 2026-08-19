edge Road {}
edge Rail {}
node Stop { has name: str; has seen: bool = False; }

walker RailRider {
    has names: list = [];
    can step with Stop entry {
        if not here.seen {
            here.seen = True;
            self.names.append(here.name);
            visit [->:Rail:->];
        }
    }
}

def rail_reachable_names(spec: dict) -> list {
    reg: dict = {};
    reg[spec["start"]] = Stop(name=spec["start"]);
    for pr in spec["roads"] { for nm in pr { if nm not in reg { reg[nm] = Stop(name=nm); } } }
    for pr in spec["rails"] { for nm in pr { if nm not in reg { reg[nm] = Stop(name=nm); } } }
    for pr in spec["roads"] { reg[pr[0]] +>:Road:+> reg[pr[1]]; }
    for pr in spec["rails"] { reg[pr[0]] +>:Rail:+> reg[pr[1]]; }
    wk = reg[spec["start"]] spawn RailRider();
    return sorted(wk.names);
}

with entry {
    print(rail_reachable_names({'roads': [['a', 'b']], 'rails': [['a', 'c'], ['c', 'd']], 'start': 'a'}));
}
