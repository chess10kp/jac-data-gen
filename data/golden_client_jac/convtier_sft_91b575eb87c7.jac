node Vine { has name: str; has val: int; }

walker VineSum {
    has total: int = 0;
    can add with Vine entry {
        self.total = here.val;
        for c in [-->] {
            s = (c spawn VineSum()).total;
            if s > 0 { self.total += s; }
        }
    }
}

def positive_branch_sum(spec: dict) -> int {
    kids: dict = dict(spec["kids"]); vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for nm in vals.keys() { nodes[nm] = Vine(name=str(nm), val=int(vals[nm])); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[spec["base"]] spawn VineSum()).total;
}

with entry {
    print(positive_branch_sum({'kids': {'a': ['b', 'c']}, 'vals': {'a': 10, 'b': -5, 'c': 3}, 'base': 'a'}));
}
