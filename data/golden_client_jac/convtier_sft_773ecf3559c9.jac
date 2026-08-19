node Limb { has name: str; }

walker LimbCount {
    has count: int = 0;
    can tally with Limb entry {
        self.count = 1;
        for c in [-->] { self.count += (c spawn LimbCount()).count; }
    }
}

def subtree_node_count(spec: dict) -> int {
    kids: dict = dict(spec["kids"]);
    nodes: dict = {};
    for (p, cs) in kids.items() {
        if p not in nodes { nodes[p] = Limb(name=str(p)); }
        for c in cs { if c not in nodes { nodes[c] = Limb(name=str(c)); } }
    }
    base: str = str(spec["base"]);
    if base not in nodes { nodes[base] = Limb(name=base); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[base] spawn LimbCount()).count;
}

with entry {
    print(subtree_node_count({'kids': {'a': ['b', 'c'], 'b': ['d']}, 'base': 'a'}));
}
