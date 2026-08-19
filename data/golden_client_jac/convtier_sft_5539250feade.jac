node Cache { has key: str; has amount: int; has tier: int = -1; }

walker BudgetScan {
    has cap: int;
    has total: int = 0;
    can gather with Cache entry {
        self.total += here.amount;
        if here.tier >= self.cap { return; }
        for nb in [-->(?tier == -1)] {
            nb.tier = here.tier + 1;
            visit nb;
        }
    }
}

def sum_within_depth(spec: dict) -> int {
    plan: dict = dict(spec["nodes"]);
    caches: dict = {};
    for (nm, info) in plan.items() { caches[nm] = Cache(key=str(nm), amount=int(info["val"])); }
    for (nm, info) in plan.items() { for t in list(info["to"]) { caches[nm] ++> caches[t]; } }
    caches[spec["start"]].tier = 0;
    w = caches[spec["start"]] spawn BudgetScan(cap=int(spec["depth"]));
    return w.total;
}

with entry {
    print(sum_within_depth({'nodes': {'a': {'val': 1, 'to': ['b', 'c']}, 'b': {'val': 2, 'to': ['d']}, 'c': {'val': 3, 'to': []}, 'd': {'val': 40, 'to': []}}, 'start': 'a', 'depth': 1}));
}
