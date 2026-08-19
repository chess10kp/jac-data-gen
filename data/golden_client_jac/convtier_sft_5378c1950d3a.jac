node Junction { has name: str; has seen: bool = False; }
edge Road { has label: str; has dist: int; }

walker RoadScout {
    has best_w: int = -1;
    has best_name: str = "";
    can scout with Junction entry {
        if not here.seen {
            here.seen = True;
            for e in [edge here -->] {
                if e.dist > self.best_w {
                    self.best_w = e.dist;
                    self.best_name = e.label;
                }
            }
            visit [-->];
        }
    }
}

def heaviest_road_name(spec: dict) -> str {
    nodes: dict = {};
    for tr in spec["edges"] {
        for nm in [tr[0], tr[1]] {
            if nm not in nodes { nodes[nm] = Junction(name=str(nm)); }
        }
    }
    for tr in spec["edges"] {
        nodes[tr[0]] +>:Road(label=str(tr[2]), dist=int(tr[3])):+> nodes[tr[1]];
    }
    w = nodes[spec["start"]] spawn RoadScout();
    return w.best_name;
}

with entry {
    print(heaviest_road_name({'edges': [['a', 'b', 'R1', 5], ['a', 'c', 'R2', 8], ['b', 'd', 'R3', 2]], 'start': 'a'}));
}
