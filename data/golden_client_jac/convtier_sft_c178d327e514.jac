node Meter { has name: str; has reading: int; has probed: bool = False; }

walker Scan {
    has limit: int;
    has hit: bool = False;
    can probe with Meter entry {
        if not here.probed {
            here.probed = True;
            if here.reading > self.limit { self.hit = True; disengage; }
            visit [-->];
        }
    }
}

def any_over_limit(spec: dict) -> bool {
    adj: dict = spec["adj"]; vals: dict = spec["vals"];
    reg: dict = {};
    for (src, outs) in adj.items() {
        if src not in reg { reg[src] = Meter(name=src, reading=vals[src]); }
        for o in outs { if o not in reg { reg[o] = Meter(name=o, reading=vals[o]); } }
    }
    for (src, outs) in adj.items() { for o in outs { reg[src] ++> reg[o]; } }
    agent = reg[spec["start"]] spawn Scan(limit=spec["limit"]);
    return agent.hit;
}

with entry {
    print(any_over_limit({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': [], 'd': []}, 'vals': {'a': 2, 'b': 3, 'c': 4, 'd': 9}, 'start': 'a', 'limit': 5}));
}
