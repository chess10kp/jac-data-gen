node Zone { has zid: str; has ring: int = -1; }

walker RingCounter {
    has d: int;
    has size: int = 0;
    can expand with Zone entry {
        if here.ring == self.d {
            self.size += 1;
        } elif here.ring < self.d {
            for nb in [-->] {
                if nb.ring == -1 { nb.ring = here.ring + 1; visit nb; }
            }
        }
    }
}

def frontier_size(spec: dict) -> int {
    adj: dict = dict(spec["adj"]);
    zones: dict = {};
    for s in adj.keys() {
        if s not in zones { zones[s] = Zone(zid=str(s)); }
        for t in adj[s] {
            if t not in zones { zones[t] = Zone(zid=str(t)); }
        }
    }
    for s in adj.keys() { for t in adj[s] { zones[s] ++> zones[t]; } }
    zones[spec["start"]].ring = 0;
    w = zones[spec["start"]] spawn RingCounter(d=int(spec["depth"]));
    return w.size;
}

with entry {
    print(frontier_size({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d', 'e'], 'd': [], 'e': []}, 'start': 'a', 'depth': 1}));
}
