node Sprig { has name: str; }

walker LeafGather {
    has found: list = [];
    can gather with Sprig entry {
        children = [-->];
        if not children { self.found = [here.name]; }
        else {
            acc = [];
            for c in children { acc.extend((c spawn LeafGather()).found); }
            self.found = sorted(acc);
        }
    }
}

def leaf_label_merge(spec: dict) -> list {
    kids: dict = dict(spec["kids"]);
    nodes: dict = {};
    for (p, cs) in kids.items() {
        if p not in nodes { nodes[p] = Sprig(name=str(p)); }
        for c in cs { if c not in nodes { nodes[c] = Sprig(name=str(c)); } }
    }
    base: str = str(spec["base"]);
    if base not in nodes { nodes[base] = Sprig(name=base); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[base] spawn LeafGather()).found;
}

with entry {
    print(leaf_label_merge({'kids': {'a': ['c', 'b'], 'c': ['e', 'd']}, 'base': 'a'}));
}
