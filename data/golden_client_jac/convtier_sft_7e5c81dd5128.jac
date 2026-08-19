node Stop { has name: str; has toured: bool = False; }

walker Tour {
    has route: list = [];
    can ride with Stop entry {
        if here.toured { return; }
        here.toured = True;
        self.route.append(here.name);
        visit [-->];
    }
}

def bfs_visit_order(spec: dict) -> list {
    adj: dict = dict(spec["adj"]);
    reg: dict = {};
    for (src, outs) in adj.items() {
        if src not in reg { reg[src] = Stop(name=str(src)); }
        for dst in outs { if dst not in reg { reg[dst] = Stop(name=str(dst)); } }
    }
    for (src, outs) in adj.items() { for dst in outs { reg[src] ++> reg[dst]; } }
    w = reg[spec["start"]] spawn Tour();
    return w.route;
}

with entry {
    print(bfs_visit_order({'adj': {'s': ['b', 'a'], 'a': ['d'], 'b': ['d', 's'], 'd': ['a']}, 'start': 's'}));
}
