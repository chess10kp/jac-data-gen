node Camp { has name: str; has d: int = 0; }
edge Trail { has dist: int; }

walker RangeCount {
    has fuel: int;
    has count: int = 0;
    can survey with Camp entry {
        if here.d <= self.fuel { self.count += 1; }
        for (nb, e) in zip([-->], [edge -->]) { nb.d = here.d + e.dist; }
        visit [-->];
    }
}

def within_fuel_count(spec: dict) -> int {
    nodes: dict = {};
    for tr in spec["edges"] {
        for nm in [tr[0], tr[1]] {
            if nm not in nodes { nodes[nm] = Camp(name=str(nm)); }
        }
    }
    for tr in spec["edges"] { nodes[tr[0]] +>:Trail(dist=int(tr[2])):+> nodes[tr[1]]; }
    return (nodes[spec["start"]] spawn RangeCount(fuel=int(spec["fuel"]))).count;
}

with entry {
    print(within_fuel_count({'edges': [['a', 'b', 4], ['a', 'c', 1], ['c', 'd', 2]], 'start': 'a', 'fuel': 3}));
}
