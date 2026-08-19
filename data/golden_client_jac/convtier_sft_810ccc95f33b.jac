node Junction { has name: str; has seen: bool = False; }
edge Road { has kind: str; has dist: int; }

walker KindLedger {
    has totals: dict = {};
    can tally with Junction entry {
        if not here.seen {
            here.seen = True;
            for e in [edge here -->] {
                self.totals[e.kind] = self.totals.get(e.kind, 0) + e.dist;
            }
            visit [-->];
        }
    }
}

def busiest_kind(spec: dict) -> str {
    nodes: dict = {};
    for tr in spec["edges"] {
        for nm in [tr[0], tr[1]] {
            if nm not in nodes { nodes[nm] = Junction(name=str(nm)); }
        }
    }
    for tr in spec["edges"] {
        nodes[tr[0]] +>:Road(kind=str(tr[2]), dist=int(tr[3])):+> nodes[tr[1]];
    }
    totals: dict = (nodes[spec["start"]] spawn KindLedger()).totals;
    best: str = "";
    for k in sorted(totals.keys()) {
        if best == "" or totals[k] > totals[best] { best = k; }
    }
    return best;
}

with entry {
    print(busiest_kind({'edges': [['a', 'b', 'rail', 4], ['a', 'c', 'road', 7], ['b', 'd', 'rail', 5]], 'start': 'a'}));
}
