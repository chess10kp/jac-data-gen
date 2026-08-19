node Rise { has name: str; }

walker HeightProbe {
    has h: int = 0;
    can climb with Rise entry {
        best = 0;
        for c in [-->] {
            d = (c spawn HeightProbe()).h;
            if d > best { best = d; }
        }
        self.h = best + 1;
    }
}

def tree_height(spec: dict) -> int {
    kids: dict = dict(spec["kids"]);
    nodes: dict = {};
    for (p, cs) in kids.items() {
        if p not in nodes { nodes[p] = Rise(name=str(p)); }
        for c in cs { if c not in nodes { nodes[c] = Rise(name=str(c)); } }
    }
    base: str = str(spec["base"]);
    if base not in nodes { nodes[base] = Rise(name=base); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[base] spawn HeightProbe()).h;
}

with entry {
    print(tree_height({'kids': {'t': ['u', 'v'], 'v': ['w'], 'w': ['x']}, 'base': 't'}));
}
