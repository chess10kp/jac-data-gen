node Prong { has name: str; }

walker ProngSize {
    has n: int = 0;
    can count with Prong entry {
        self.n = 1;
        for c in [-->] { self.n += (c spawn ProngSize()).n; }
    }
}

def arms_balanced(spec: dict) -> bool {
    kids: dict = dict(spec["kids"]);
    nodes: dict = {};
    for (p, cs) in kids.items() {
        if p not in nodes { nodes[p] = Prong(name=str(p)); }
        for c in cs { if c not in nodes { nodes[c] = Prong(name=str(c)); } }
    }
    base: str = str(spec["base"]);
    if base not in nodes { nodes[base] = Prong(name=base); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    sizes: list = [];
    for ch in kids.get(base, []) { sizes.append((nodes[ch] spawn ProngSize()).n); }
    return len(set(sizes)) <= 1;
}

with entry {
    print(arms_balanced({'kids': {'c': ['l', 'r'], 'l': ['l1'], 'r': ['r1']}, 'base': 'c'}));
}
