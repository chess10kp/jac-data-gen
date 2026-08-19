node Junction { has name: str; has seen: bool = False; }
edge Road { has toll: int; }

walker TollAudit {
    has total: int = 0;
    can audit with Junction entry {
        if not here.seen {
            here.seen = True;
            for e in [edge here -->] { self.total += e.toll; }
            visit [-->];
        }
    }
}

def reachable_toll_sum(spec: dict) -> int {
    nodes: dict = {};
    for tr in spec["edges"] {
        for nm in [tr[0], tr[1]] {
            if nm not in nodes { nodes[nm] = Junction(name=str(nm)); }
        }
    }
    for tr in spec["edges"] { nodes[tr[0]] +>:Road(toll=int(tr[2])):+> nodes[tr[1]]; }
    return (nodes[spec["start"]] spawn TollAudit()).total;
}

with entry {
    print(reachable_toll_sum({'edges': [['a', 'b', 2], ['a', 'c', 3], ['b', 'd', 4], ['c', 'd', 5]], 'start': 'a'}));
}
