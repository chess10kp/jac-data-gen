node Junction { has name: str; has seen: bool = False; }
edge Road { has dist: int; }

walker LengthGather {
    has found: list = [];
    can gather with Junction entry {
        if not here.seen {
            here.seen = True;
            for e in [edge here -->] { self.found.append(e.dist); }
            visit [-->];
        }
    }
}

def sorted_road_lengths(spec: dict) -> list {
    nodes: dict = {};
    for tr in spec["edges"] {
        for nm in [tr[0], tr[1]] {
            if nm not in nodes { nodes[nm] = Junction(name=str(nm)); }
        }
    }
    for tr in spec["edges"] { nodes[tr[0]] +>:Road(dist=int(tr[2])):+> nodes[tr[1]]; }
    return sorted((nodes[spec["start"]] spawn LengthGather()).found);
}

with entry {
    print(sorted_road_lengths({'edges': [['a', 'b', 5], ['a', 'c', 2], ['c', 'd', 9]], 'start': 'a'}));
}
