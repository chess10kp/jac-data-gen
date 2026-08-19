node Junction { has name: str; has seen: bool = False; }
edge Road { has kind: str; }

walker KindCollect {
    has kinds: list = [];
    can collect with Junction entry {
        if not here.seen {
            here.seen = True;
            for e in [edge here -->] {
                if e.kind not in self.kinds { self.kinds.append(e.kind); }
            }
            visit [-->];
        }
    }
}

def road_kinds(spec: dict) -> list {
    nodes: dict = {};
    for tr in spec["edges"] {
        for nm in [tr[0], tr[1]] {
            if nm not in nodes { nodes[nm] = Junction(name=str(nm)); }
        }
    }
    for tr in spec["edges"] { nodes[tr[0]] +>:Road(kind=str(tr[2])):+> nodes[tr[1]]; }
    return sorted((nodes[spec["start"]] spawn KindCollect()).kinds);
}

with entry {
    print(road_kinds({'edges': [['a', 'b', 'paved'], ['a', 'c', 'dirt'], ['b', 'd', 'paved']], 'start': 'a'}));
}
