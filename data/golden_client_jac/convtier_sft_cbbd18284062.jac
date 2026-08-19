node Twig { has label: str; has deep: int = -1; }

walker Pruner {
    has fence: int;
    has picks: list = [];
    can clip with Twig entry {
        if len([-->]) == 0 { self.picks.append(here.label); }
        if here.deep >= self.fence { return; }
        for branch in [-->(?deep == -1)] {
            branch.deep = here.deep + 1;
            visit branch;
        }
    }
}

def bounded_leaf_names(spec: dict) -> list {
    twigs: dict = {};
    for (par, kids) in dict(spec["adj"]).items() {
        if par not in twigs { twigs[par] = Twig(label=str(par)); }
        for kid in kids {
            if kid not in twigs { twigs[kid] = Twig(label=str(kid)); }
            twigs[par] ++> twigs[kid];
        }
    }
    entrance = twigs[spec["start"]];
    entrance.deep = 0;
    w = entrance spawn Pruner(fence=int(spec["depth"]));
    return sorted(w.picks);
}

with entry {
    print(bounded_leaf_names({'adj': {'a': ['b', 'c'], 'b': ['d', 'e'], 'c': [], 'd': [], 'e': []}, 'start': 'a', 'depth': 1}));
}
