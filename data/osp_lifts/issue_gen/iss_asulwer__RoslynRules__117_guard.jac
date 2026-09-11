"""asulwer/RoslynRules#117 — rule dependency profiler call tree."""

node Rule {
    has rid: str;
}

edge ChildOf {}

edge Depends {}

obj RuleStore {
    has rules: dict[str, Rule] = {};
    has parent_of: dict[str, str | None] = {};
}

walker DepReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Rule entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        self.reached.append(here.rid);
        visit [->:Depends:->][?:Rule];
    }
}

def load_rules(
    rules: list[tuple[str, str | None]],
    depends_edges: list[tuple[str, str]],
) -> RuleStore {
    store = RuleStore();
    for (rid, parent) in rules {
        nd = Rule(rid=rid);
        root ++> nd;
        store.rules[rid] = nd;
        store.parent_of[rid] = parent;
    }
    for (rid, parent) in rules {
        if parent is not None {
            p: Rule | None = store.rules.get(parent, None);
            nd: Rule | None = store.rules.get(rid, None);
            if p is not None and nd is not None {
                p +>:ChildOf:+> nd;
                p +>:Depends:+> nd;
            }
        }
    }
    for (dep, rule) in depends_edges {
        d = store.rules.get(dep, None);
        r = store.rules.get(rule, None);
        if d is not None and r is not None { d +>:Depends:+> r; }
    }
    return store;
}

def rule_ancestors(store: RuleStore, rule_id: str) -> list[str] {
    if not (rule_id in store.parent_of) { return []; }
    chain: list[str] = [];
    cur: str | None = rule_id;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur in seen { break; }
        seen[cur] = True;
        chain.append(cur);
        cur = store.parent_of.get(cur, None);
    }
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

def dependent_rules(store: RuleStore, `root: str) -> list[str] {
    nd = store.rules.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DepReach(claimed={}, reached=[]);
    return sorted(w.reached);
}

def profile_self_ms(store: RuleStore, rule_id: str, ticks: dict[str, int]) -> int {
    if store.rules.get(rule_id, None) is None { return 0; }
    return ticks.get(rule_id, 0);
}

def profile_total_ms(store: RuleStore, rule_id: str, ticks: dict[str, int]) -> int {
    total = profile_self_ms(store, rule_id, ticks);
    for dep in dependent_rules(store, rule_id) {
        if dep != rule_id { total += ticks.get(dep, 0); }
    }
    return total;
}

test "rule dependency profiler" {
    store = load_rules(
        [("leaf", "parent"), ("parent", "root"), ("root", None), ("sibling", "root")],
        [("root", "leaf"), ("root", "sibling"), ("parent", "leaf")],
    );
    assert rule_ancestors(store, "leaf") == ["root", "parent", "leaf"];
    assert dependent_rules(store, "root") == ["leaf", "parent", "root", "sibling"];
    ticks = {"root": 1, "parent": 2, "leaf": 3, "sibling": 4};
    assert profile_self_ms(store, "leaf", ticks) == 3;
    assert profile_total_ms(store, "root", ticks) == 10;
}
