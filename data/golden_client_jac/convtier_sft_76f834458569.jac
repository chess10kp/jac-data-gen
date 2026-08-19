node Twig { has name: str; }

walker LeafScan {
    has n: int = 0;
    can scan with Twig entry {
        children = [-->];
        if not children { self.n = 1; }
        else {
            for c in children { self.n += (c spawn LeafScan()).n; }
        }
    }
}

def leaf_tally(spec: dict) -> int {
    kids: dict = dict(spec["kids"]);
    nodes: dict = {};
    for (p, cs) in kids.items() {
        if p not in nodes { nodes[p] = Twig(name=str(p)); }
        for c in cs { if c not in nodes { nodes[c] = Twig(name=str(c)); } }
    }
    base: str = str(spec["base"]);
    if base not in nodes { nodes[base] = Twig(name=base); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[base] spawn LeafScan()).n;
}

with entry {
    print(leaf_tally({'kids': {'a': ['b', 'c', 'd'], 'c': ['e', 'f']}, 'base': 'a'}));
}
