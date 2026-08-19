node Frond { has name: str; }

walker DeepProbe {
    has depth: int = 0;
    has leaf: str = "";
    can seek with Frond entry {
        children = [-->];
        if not children { self.depth = 0; self.leaf = here.name; }
        else {
            bd = -1; bn = "";
            for c in children {
                w = c spawn DeepProbe();
                cd = w.depth + 1;
                if cd > bd or (cd == bd and w.leaf < bn) { bd = cd; bn = w.leaf; }
            }
            self.depth = bd; self.leaf = bn;
        }
    }
}

def deepest_leaf_name(spec: dict) -> str {
    kids: dict = dict(spec["kids"]);
    nodes: dict = {};
    for (p, cs) in kids.items() {
        if p not in nodes { nodes[p] = Frond(name=str(p)); }
        for c in cs { if c not in nodes { nodes[c] = Frond(name=str(c)); } }
    }
    base: str = str(spec["base"]);
    if base not in nodes { nodes[base] = Frond(name=base); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[base] spawn DeepProbe()).leaf;
}

with entry {
    print(deepest_leaf_name({'kids': {'a': ['b', 'c'], 'b': ['d'], 'c': ['e']}, 'base': 'a'}));
}
