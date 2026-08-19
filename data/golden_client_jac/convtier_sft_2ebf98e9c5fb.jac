node Cave { has tag: str; has explored: bool = False; }

walker Spelunk {
    has answer: str = "none";
    can crawl with Cave entry {
        if here.explored { return; }
        here.explored = True;
        if len([-->]) == 0 {
            self.answer = here.tag;
            disengage;
        }
        visit [-->];
    }
}

def first_dead_end(spec: dict) -> str {
    adj: dict = dict(spec["adj"]);
    reg: dict = {};
    for (src, outs) in adj.items() {
        if src not in reg { reg[src] = Cave(tag=str(src)); }
        for dst in outs { if dst not in reg { reg[dst] = Cave(tag=str(dst)); } }
    }
    for (src, outs) in adj.items() { for dst in outs { reg[src] ++> reg[dst]; } }
    w = reg[spec["start"]] spawn Spelunk();
    return w.answer;
}

with entry {
    print(first_dead_end({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': [], 'd': []}, 'start': 'a'}));
}
