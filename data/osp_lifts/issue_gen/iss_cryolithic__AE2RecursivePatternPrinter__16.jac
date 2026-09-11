"""cryolithic/AE2RecursivePatternPrinter#16 — PatternAnalyzer recursive dependency resolution."""

node Item {
    has name: str;
    has has_pattern: bool = False;
    has deps: list[str] = [];
}

edge Requires {}

obj PatternNetwork {
    has items: dict[str, Item] = {};
}

walker DepResolve {
    has store: PatternNetwork;
    has claimed: dict[str, bool] = {};
    has results: list[str] = [];

    can step with Item entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.has_pattern { skip; }
        for dep_name in here.deps {
            child = self.store.items.get(dep_name, None);
            if child is not None {
                sub = child spawn DepResolve(
                    store=self.store,
                    claimed=self.claimed,
                    results=self.results,
                );
                self.claimed = sub.claimed;
            }
        }
    }

    can finish with Item exit {
        if here.has_pattern { skip; }
        self.results.append(here.name);
    }
}

def load_network(
    recipes: dict[str, list[str]],
    existing_patterns: list[str] | None = None,
) -> PatternNetwork {
    net = PatternNetwork();
    all_names: dict[str, bool] = {};
    for (item, ingredients) in recipes.items() {
        all_names[item] = True;
        for ing in ingredients { all_names[ing] = True; }
    }
    for name in all_names.keys() {
        nd = Item(name=name);
        root ++> nd;
        net.items[name] = nd;
    }
    if existing_patterns {
        for p in existing_patterns {
            n = net.items.get(p, None);
            if n is not None { n.has_pattern = True; }
        }
    }
    for (item, ingredients) in recipes.items() {
        parent = net.items.get(item, None);
        if parent is None { continue; }
        for ing in ingredients {
            child = net.items.get(ing, None);
            if child is not None {
                parent.deps.append(ing);
                parent +>:Requires:+> child;
            }
        }
    }
    return net;
}

def analyze_pattern(
    store: PatternNetwork,
    root_inputs: list[str],
) -> list[str] {
    claimed: dict[str, bool] = {};
    results: list[str] = [];
    for inp in root_inputs {
        nd = store.items.get(inp, None);
        if nd is None { continue; }
        w = nd spawn DepResolve(store=store, claimed=claimed, results=[]);
        for r in w.results {
            if not (r in results) { results.append(r); }
        }
        claimed = w.claimed;
    }
    return results;
}

def missing_recipes(store: PatternNetwork, items: list[str]) -> list[str] {
    out: list[str] = [];
    seen: dict[str, bool] = {};
    for item in items {
        if store.items.get(item, None) is None and not (item in seen) {
            seen[item] = True;
            out.append(item);
        }
    }
    return sorted(out);
}
