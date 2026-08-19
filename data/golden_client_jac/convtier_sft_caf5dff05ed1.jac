node Pkg { has name: str; has cost: int; has counted: bool = False; }

walker CostUp {
    has total: int = 0;
    can add with Pkg entry {
        if not here.counted {
            here.counted = True;
            t = here.cost;
            for c in [-->] { t += (c spawn CostUp()).total; }
            self.total = t;
        }
    }
}

def unique_dep_cost(spec: dict) -> int {
    deps: dict = dict(spec["deps"]); cost: dict = dict(spec["cost"]);
    nodes: dict = {};
    for nm in cost.keys() { nodes[nm] = Pkg(name=str(nm), cost=int(cost[nm]), counted=False); }
    for (p, cs) in deps.items() { for c in cs { nodes[p] ++> nodes[c]; } }
    return (nodes[spec["base"]] spawn CostUp()).total;
}

with entry {
    print(unique_dep_cost({'deps': {'app': ['lib', 'ui'], 'lib': ['core'], 'ui': ['core']}, 'cost': {'app': 1, 'lib': 2, 'ui': 4, 'core': 8}, 'base': 'app'}));
}
