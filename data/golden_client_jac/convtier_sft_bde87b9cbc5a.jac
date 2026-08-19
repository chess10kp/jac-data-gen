node Rung { has name: str; has level: int = -1; has seen: bool = False; }

walker Plumb {
    has deepest: int = 0;
    can sink with Rung entry {
        if here.seen { return; }
        here.seen = True;
        if here.level > self.deepest { self.deepest = here.level; }
        for nxt in [-->] {
            if nxt.level == -1 { nxt.level = here.level + 1; }
        }
        visit [-->];
    }
}

def deepest_hop(spec: dict) -> int {
    adj: dict = dict(spec["adj"]);
    reg: dict = {};
    for (src, outs) in adj.items() {
        if src not in reg { reg[src] = Rung(name=str(src)); }
        for dst in outs { if dst not in reg { reg[dst] = Rung(name=str(dst)); } }
    }
    for (src, outs) in adj.items() { for dst in outs { reg[src] ++> reg[dst]; } }
    reg[spec["start"]].level = 0;
    w = reg[spec["start"]] spawn Plumb();
    return w.deepest;
}

with entry {
    print(deepest_hop({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': ['a']}, 'start': 'a'}));
}
