node Arm { has name: str; has val: int; }

walker ArmSum {
    has total: int = 0;
    can add with Arm entry {
        self.total = here.val;
        for c in [-->] { self.total += (c spawn ArmSum()).total; }
    }
}

def child_branch_sums(spec: dict) -> dict {
    kids: dict = dict(spec["kids"]); vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for nm in vals.keys() { nodes[nm] = Arm(name=str(nm), val=int(vals[nm])); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    out: dict = {};
    for ch in sorted(kids.get(spec["base"], [])) {
        out[ch] = (nodes[ch] spawn ArmSum()).total;
    }
    return out;
}

with entry {
    print(child_branch_sums({'kids': {'h': ['p', 'q'], 'p': ['x']}, 'vals': {'h': 1, 'p': 2, 'x': 3, 'q': 7}, 'base': 'h'}));
}
