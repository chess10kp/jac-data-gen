node Crest { has name: str; has val: int; }

walker CrestMax {
    has best: int = 0;
    can rise with Crest entry {
        children = [-->];
        if not children { self.best = here.val; }
        else {
            top = (children[0] spawn CrestMax()).best;
            for c in children[1:] {
                s = (c spawn CrestMax()).best;
                if s > top { top = s; }
            }
            self.best = here.val + top;
        }
    }
}

def best_root_leaf_sum(spec: dict) -> int {
    kids: dict = dict(spec["kids"]); vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for nm in vals.keys() { nodes[nm] = Crest(name=str(nm), val=int(vals[nm])); }
    for (p, cs) in kids.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[spec["base"]] spawn CrestMax()).best;
}

with entry {
    print(best_root_leaf_sum({'kids': {'a': ['b', 'c'], 'b': ['d']}, 'vals': {'a': 1, 'b': 2, 'c': 10, 'd': 100}, 'base': 'a'}));
}
