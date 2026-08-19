edge Road {}
edge Rail {}
node Hub { has name: str; }

def out_degree_by_mode(spec: dict) -> list {
    reg: dict = {};
    reg[spec["start"]] = Hub(name=spec["start"]);
    for pr in spec["roads"] { for nm in pr { if nm not in reg { reg[nm] = Hub(name=nm); } } }
    for pr in spec["rails"] { for nm in pr { if nm not in reg { reg[nm] = Hub(name=nm); } } }
    for pr in spec["roads"] { reg[pr[0]] +>:Road:+> reg[pr[1]]; }
    for pr in spec["rails"] { reg[pr[0]] +>:Rail:+> reg[pr[1]]; }
    base = reg[spec["start"]];
    return [len([edge base ->:Road:->]), len([edge base ->:Rail:->])];
}

with entry {
    print(out_degree_by_mode({'roads': [['a', 'b'], ['a', 'c'], ['b', 'c']], 'rails': [['a', 'x']], 'start': 'a'}));
}
