edge Road { has w: int; }
edge Rail {}
node Camp { has name: str; has seen: bool = False; }

walker StrongLink {
    has min_w: int;
    has count: int = 0;
    can step with Camp entry {
        if not here.seen {
            here.seen = True;
            self.count += 1;
            visit [->:Road:w >= self.min_w:->];
            visit [->:Rail:->];
        }
    }
}

def strong_or_rail_reach(spec: dict) -> int {
    reg: dict = {};
    reg[spec["start"]] = Camp(name=spec["start"]);
    for tr in spec["roads"] { for nm in [tr[0], tr[1]] { if nm not in reg { reg[nm] = Camp(name=nm); } } }
    for pr in spec["rails"] { for nm in pr { if nm not in reg { reg[nm] = Camp(name=nm); } } }
    for tr in spec["roads"] { reg[tr[0]] +>:Road(w=int(tr[2])):+> reg[tr[1]]; }
    for pr in spec["rails"] { reg[pr[0]] +>:Rail:+> reg[pr[1]]; }
    wk = reg[spec["start"]] spawn StrongLink(min_w=int(spec["min_w"]));
    return wk.count;
}

with entry {
    print(strong_or_rail_reach({'roads': [['a', 'b', 5], ['a', 'c', 1], ['b', 'd', 4]], 'rails': [['c', 'e']], 'min_w': 3, 'start': 'a'}));
}
