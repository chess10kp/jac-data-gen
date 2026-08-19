edge Wire { has w: int; }
node Hub { has name: str; has power: int; has lit: bool = False; }

walker Surge {
    has min_w: int;
    has best: int = -2147483648;
    can spread with Hub entry {
        if not here.lit {
            here.lit = True;
            if here.power > self.best { self.best = here.power; }
            visit [->:Wire:w >= self.min_w:->];
        }
    }
}

def strong_edge_max(spec: dict) -> int {
    adj: dict = spec["adj"]; vals: dict = spec["vals"];
    reg: dict = {};
    for (src, pairs) in adj.items() {
        if src not in reg { reg[src] = Hub(name=src, power=vals[src]); }
        for pr in pairs { if pr[0] not in reg { reg[pr[0]] = Hub(name=pr[0], power=vals[pr[0]]); } }
    }
    for (src, pairs) in adj.items() { for pr in pairs { reg[src] +>:Wire(w=pr[1]):+> reg[pr[0]]; } }
    agent = reg[spec["start"]] spawn Surge(min_w=spec["min_w"]);
    return agent.best;
}

with entry {
    print(strong_edge_max({'adj': {'a': [['b', 5], ['c', 1]], 'b': [['d', 4]], 'c': [], 'd': []}, 'vals': {'a': 3, 'b': 6, 'c': 99, 'd': 8}, 'start': 'a', 'min_w': 3}));
}
