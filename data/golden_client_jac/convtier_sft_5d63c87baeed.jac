node Tier { has name: str; has val: int; }

walker WaveSum {
    has sign: int = 1;
    has total: int = 0;
    can sweep with Tier entry {
        self.total = self.sign * here.val;
        for c in [-->] { self.total += (c spawn WaveSum(sign=-self.sign)).total; }
    }
}

def level_signed_sum(spec: dict) -> int {
    kids: dict = dict(spec["kids"]); vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for nm in vals.keys() { nodes[nm] = Tier(name=str(nm), val=int(vals[nm])); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[spec["base"]] spawn WaveSum(sign=1)).total;
}

with entry {
    print(level_signed_sum({'kids': {'a': ['b', 'c'], 'b': ['d']}, 'vals': {'a': 10, 'b': 1, 'c': 2, 'd': 5}, 'base': 'a'}));
}
