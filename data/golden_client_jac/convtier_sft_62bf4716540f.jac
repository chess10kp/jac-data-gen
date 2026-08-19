node Kiosk { has label: str; has cost: int; }

walker BudgetWalk {
    has budget: int = 0;
    has spent: int = 0;
    has names: list = [];
    can shop with Kiosk entry {
        if self.spent + here.cost > self.budget { disengage; }
        self.spent += here.cost;
        self.names.append(here.label);
        visit [-->];
    }
}

def budget_walk_labels(spec: dict) -> list {
    kiosks: list = [Kiosk(label=str(pr[0]), cost=int(pr[1])) for pr in spec["stops"]];
    if len(kiosks) == 0 { return []; }
    k: int = 0;
    while k + 1 < len(kiosks) { kiosks[k] ++> kiosks[k + 1]; k += 1; }
    shopper = kiosks[0] spawn BudgetWalk(budget=int(spec["budget"]));
    return shopper.names;
}

with entry {
    print(budget_walk_labels({'stops': [['a', 3], ['b', 4], ['c', 9], ['d', 1]], 'budget': 8}));
}
