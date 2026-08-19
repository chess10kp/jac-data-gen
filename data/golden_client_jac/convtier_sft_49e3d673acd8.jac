node Stone { has name: str; has size: int = 0; }

walker SizeStamp {
    has n: int = 0;
    can mark with Stone entry {
        t = 1;
        for c in [-->] { t += (c spawn SizeStamp()).n; }
        here.size = t;
        self.n = t;
    }
}

def heavy_subtree_count(spec: dict) -> int {
    kids: dict = dict(spec["kids"]);
    nodes: dict = {};
    for (p, cs) in kids.items() {
        if p not in nodes { nodes[p] = Stone(name=str(p)); }
        for c in cs { if c not in nodes { nodes[c] = Stone(name=str(c)); } }
    }
    base: str = str(spec["base"]);
    if base not in nodes { nodes[base] = Stone(name=base); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    total: int = (nodes[base] spawn SizeStamp()).n;
    heavy: int = 0;
    for nd in nodes.values() { if 2 * nd.size >= total { heavy += 1; } }
    return heavy;
}

with entry {
    print(heavy_subtree_count({'kids': {'a': ['b', 'c'], 'b': ['d', 'e']}, 'base': 'a'}));
}
