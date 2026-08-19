node Depot { has name: str; has seen: bool = False; }
edge Lane { has load: int; }

walker Hauler {
    has cap: int;
    has count: int = 0;
    can roll with Depot entry {
        if not here.seen {
            here.seen = True;
            self.count += 1;
            visit [->:Lane:load <= self.cap:->];
        }
    }
}

def light_load_reach(spec: dict) -> int {
    nodes: dict = {};
    for tr in spec["edges"] {
        for nm in [tr[0], tr[1]] {
            if nm not in nodes { nodes[nm] = Depot(name=str(nm)); }
        }
    }
    for tr in spec["edges"] { nodes[tr[0]] +>:Lane(load=int(tr[2])):+> nodes[tr[1]]; }
    return (nodes[spec["start"]] spawn Hauler(cap=int(spec["cap"]))).count;
}

with entry {
    print(light_load_reach({'edges': [['a', 'b', 3], ['a', 'c', 9], ['b', 'd', 2]], 'start': 'a', 'cap': 5}));
}
