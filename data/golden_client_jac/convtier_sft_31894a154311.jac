node Zone { has name: str; has ring: int = -1; has scanned: bool = False; }

walker Radar {
    has reach: int;
    has blips: int = 0;
    can ping with Zone entry {
        if here.scanned { return; }
        here.scanned = True;
        self.blips += 1;
        if here.ring < self.reach {
            for nxt in [-->] {
                if nxt.ring == -1 { nxt.ring = here.ring + 1; }
            }
            visit [-->];
        }
    }
}

def count_within_hops(spec: dict) -> int {
    adj: dict = dict(spec["adj"]);
    reg: dict = {};
    for (src, outs) in adj.items() {
        if src not in reg { reg[src] = Zone(name=str(src)); }
        for dst in outs { if dst not in reg { reg[dst] = Zone(name=str(dst)); } }
    }
    for (src, outs) in adj.items() { for dst in outs { reg[src] ++> reg[dst]; } }
    reg[spec["start"]].ring = 0;
    w = reg[spec["start"]] spawn Radar(reach=int(spec["limit"]));
    return w.blips;
}

with entry {
    print(count_within_hops({'adj': {'h': ['i', 'j'], 'i': ['k'], 'j': ['k'], 'k': ['l'], 'l': []}, 'start': 'h', 'limit': 2}));
}
