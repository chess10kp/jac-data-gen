node Room { has name: str; has level: int; has entered: bool = False; }

walker Explore {
    has gate: int;
    has reached: int = 0;
    can enter with Room entry {
        if not here.entered {
            here.entered = True;
            self.reached += 1;
            if here.level >= self.gate { visit [-->]; }
        }
    }
}

def gated_count(spec: dict) -> int {
    adj: dict = spec["adj"]; vals: dict = spec["vals"];
    known: list = list(adj.keys());
    for group in adj.values() { for g in group { if g not in known { known.append(g); } } }
    rooms: dict = {};
    for nm in known { rooms[nm] = Room(name=nm, level=vals[nm]); }
    for (src, group) in adj.items() { for g in group { rooms[src] ++> rooms[g]; } }
    w = rooms[spec["start"]] spawn Explore(gate=spec["gate"]);
    return w.reached;
}

with entry {
    print(gated_count({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['e'], 'd': [], 'e': []}, 'vals': {'a': 5, 'b': 1, 'c': 6, 'd': 9, 'e': 2}, 'start': 'a', 'gate': 4}));
}
