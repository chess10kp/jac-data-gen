node Pod { has name: str; has load: int; has toured: bool = False; }

walker Seek {
    has best: int = -1;
    can weigh with Pod entry {
        if not here.toured {
            here.toured = True;
            if here.load > 0 and (self.best == -1 or here.load < self.best) { self.best = here.load; }
            visit [-->];
        }
    }
}

def min_over_positive(spec: dict) -> int {
    adj: dict = spec["adj"]; vals: dict = spec["vals"];
    pods: dict = {};
    for (src, outs) in adj.items() {
        if src not in pods { pods[src] = Pod(name=src, load=vals[src]); }
        for o in outs { if o not in pods { pods[o] = Pod(name=o, load=vals[o]); } }
    }
    for (src, outs) in adj.items() { for o in outs { pods[src] ++> pods[o]; } }
    agent = pods[spec["start"]] spawn Seek();
    return agent.best;
}

with entry {
    print(min_over_positive({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'vals': {'a': 7, 'b': -2, 'c': 3, 'd': 0}, 'start': 'a'}));
}
