"""Emrys02/soroban-band#7 — contract dependency cycle detection."""

node Contract {
    has name: str;
}

edge DependsOn {}

obj ContractGraph {
    has contracts: dict[str, Contract] = {};
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with Contract entry {
        if here.name in self.visited { skip; }
        self.visited[here.name] = True;
        self.stack[here.name] = True;
        for dep in [here ->:DependsOn:->][?:Contract] {
            if dep.name in self.stack {
                self.errors.append((here.name, dep.name));
            } else {
                if not (dep.name in self.visited) { visit [dep]; }
            }
        }
        self.stack[here.name] = False;
    }
}

def load_contracts(
    names: list[str],
    depends_edges: list[tuple[str, str]],
) -> ContractGraph {
    g = ContractGraph();
    for name in names {
        nd = Contract(name=name);
        root ++> nd;
        g.contracts[name] = nd;
    }
    for (blocker, blocked) in depends_edges {
        b = g.contracts.get(blocker, None);
        d = g.contracts.get(blocked, None);
        if b is not None and d is not None { d +>:DependsOn:+> b; }
    }
    return g;
}

def detect_cycles(store: ContractGraph) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(store.contracts.keys()) {
        if k in visited { continue; }
        nd = store.contracts[k];
        w = nd spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

def cycle_members(store: ContractGraph, start: str) -> list[str] | None {
    nd = store.contracts.get(start, None);
    if nd is None { return None; }
    w = nd spawn CycleProbe(visited={}, stack={}, errors=[]);
    if len(w.errors) == 0 { return None; }
    (a, b) = w.errors[0];
    return [a, b];
}

def build_order(store: ContractGraph) -> list[str] {
    indeg: dict[str, int] = {};
    for n in store.contracts.keys() { indeg[n] = 0; }
    for (name, nd) in store.contracts.items() {
        for dep in [nd ->:DependsOn:->][?:Contract] {
            indeg[name] += 1;
        }
    }
    ready = sorted([n for (n, d) in indeg.items() if d == 0]);
    order: list[str] = [];
    while len(ready) > 0 {
        cur = ready.pop(0);
        order.append(cur);
        cnd = store.contracts.get(cur, None);
        if cnd is None { continue; }
        for other in store.contracts.keys() {
            ond = store.contracts.get(other, None);
            if ond is None { continue; }
            for dep in [ond ->:DependsOn:->][?:Contract] {
                if dep.name == cur {
                    indeg[other] -= 1;
                    if indeg[other] == 0 {
                        ready.append(other);
                        ready = sorted(ready);
                    }
                }
            }
        }
    }
    if len(order) != len(store.contracts) { return []; }
    return order;
}
