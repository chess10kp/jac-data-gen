edge Road {}
edge Rail {}
node Station { has name: str; has seen: bool = False; }

walker FindInterchanges {
    has hits: list = [];
    can scan with Station entry {
        if not here.seen {
            here.seen = True;
            if len([edge here ->:Road:->]) > 0 and len([edge here ->:Rail:->]) > 0 {
                self.hits.append(here.name);
            }
            visit [-->];
        }
    }
}

def interchange_names(spec: dict) -> list {
    reg: dict = {};
    reg[spec["start"]] = Station(name=spec["start"]);
    for pr in spec["roads"] { for nm in pr { if nm not in reg { reg[nm] = Station(name=nm); } } }
    for pr in spec["rails"] { for nm in pr { if nm not in reg { reg[nm] = Station(name=nm); } } }
    for pr in spec["roads"] { reg[pr[0]] +>:Road:+> reg[pr[1]]; }
    for pr in spec["rails"] { reg[pr[0]] +>:Rail:+> reg[pr[1]]; }
    wk = reg[spec["start"]] spawn FindInterchanges();
    return sorted(wk.hits);
}

with entry {
    print(interchange_names({'roads': [['a', 'b'], ['b', 'c']], 'rails': [['a', 'd'], ['b', 'd']], 'start': 'a'}));
}
