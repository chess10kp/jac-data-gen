node Way { has name: str; has hops: int = -1; has walked: bool = False; }

walker Pathfinder {
    has goal: str;
    has result: int = -1;
    can advance with Way entry {
        if here.walked { return; }
        here.walked = True;
        if here.name == self.goal {
            self.result = here.hops;
            disengage;
        }
        for nxt in [-->] {
            if nxt.hops == -1 { nxt.hops = here.hops + 1; }
        }
        visit [-->];
    }
}

def hops_between(spec: dict) -> int {
    adj: dict = dict(spec["adj"]);
    reg: dict = {};
    for (src, outs) in adj.items() {
        if src not in reg { reg[src] = Way(name=str(src)); }
        for dst in outs { if dst not in reg { reg[dst] = Way(name=str(dst)); } }
    }
    for (src, outs) in adj.items() { for dst in outs { reg[src] ++> reg[dst]; } }
    reg[spec["start"]].hops = 0;
    w = reg[spec["start"]] spawn Pathfinder(goal=str(spec["goal"]));
    return w.result;
}

with entry {
    print(hops_between({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': ['e'], 'e': []}, 'start': 'a', 'goal': 'e'}));
}
