node Spot { has name: str; has visited: bool = False; }

walker Probe {
    has target: str;
    has found: bool = False;
    can hunt with Spot entry {
        if here.visited { return; }
        here.visited = True;
        if here.name == self.target { self.found = True; disengage; }
        visit [-->];
    }
}

def can_reach(spec: dict) -> bool {
    adj: dict = dict(spec["adj"]);
    reg: dict = {};
    for (src, outs) in adj.items() {
        if src not in reg { reg[src] = Spot(name=str(src)); }
        for dst in outs { if dst not in reg { reg[dst] = Spot(name=str(dst)); } }
    }
    for (src, outs) in adj.items() { for dst in outs { reg[src] ++> reg[dst]; } }
    w = reg[spec["start"]] spawn Probe(target=str(spec["target"]));
    return w.found;
}

with entry {
    print(can_reach({'adj': {'a': ['b'], 'b': ['c', 'a'], 'c': []}, 'start': 'a', 'target': 'c'}));
}
