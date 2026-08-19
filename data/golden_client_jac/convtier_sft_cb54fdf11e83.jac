node Bough { has name: str; has val: int; }

walker BoughSum {
    has total: int = 0;
    can add with Bough entry {
        self.total = here.val;
        for c in [-->] { self.total += (c spawn BoughSum()).total; }
    }
}

def branch_total(spec: dict) -> int {
    kids: dict = dict(spec["kids"]); vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for nm in vals.keys() { nodes[nm] = Bough(name=str(nm), val=int(vals[nm])); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[spec["base"]] spawn BoughSum()).total;
}

with entry {
    print(branch_total({'kids': {'m': ['p', 'q'], 'q': ['r']}, 'vals': {'m': 5, 'p': 3, 'q': 2, 'r': 10}, 'base': 'm'}));
}
