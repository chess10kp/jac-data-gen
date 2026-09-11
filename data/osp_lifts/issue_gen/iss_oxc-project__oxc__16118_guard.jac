"""oxc-project/oxc#16118 — Recursive linter fix loop until stable state."""

node LintRule {
    has name: str;
    has pending: bool = False;
}

edge Triggers {}

obj LintStore {
    has rules: dict[str, LintRule] = {};
}

walker TriggerReach {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with LintRule entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.anchor { self.found.append(here.name); }
        visit [->:Triggers:->][?:LintRule];
    }
}

def load_linter(
    rule_names: list[str],
    trigger_edges: list[tuple[str, str]],
    initial_pending: list[str] | None = None,
) -> LintStore {
    store = LintStore();
    for rule in rule_names {
        nd = LintRule(name=rule);
        root ++> nd;
        store.rules[rule] = nd;
    }
    for (src, dst) in trigger_edges {
        s = store.rules.get(src, None);
        d = store.rules.get(dst, None);
        if s is not None and d is not None { s +>:Triggers:+> d; }
    }
    if initial_pending is not None {
        for rule in initial_pending {
            r = store.rules.get(rule, None);
            if r is not None { r.pending = True; }
        }
    }
    return store;
}

def apply_fix_round(store: LintStore) -> list[str] {
    applied: list[str] = [];
    for name in sorted(store.rules.keys()) {
        r = store.rules[name];
        if r.pending {
            applied.append(name);
            r.pending = False;
            for nxt in [r ->:Triggers:->][?:LintRule] { nxt.pending = True; }
        }
    }
    return applied;
}

def fix_until_stable(store: LintStore, max_rounds: int = 10) -> list[list[str]] {
    rounds: list[list[str]] = [];
    for _ in range(max_rounds) {
        batch = apply_fix_round(store);
        if len(batch) == 0 { break; }
        rounds.append(batch);
    }
    return rounds;
}

def reachable_rules(store: LintStore, seed: str) -> list[str] {
    nd = store.rules.get(seed, None);
    if nd is None { return []; }
    w = nd spawn TriggerReach(claimed={}, anchor=seed);
    return sorted(w.found);
}

test "recursive fix rounds" {
    g = load_linter(["a", "b", "c"], [("a", "b"), ("b", "c")], initial_pending=["a"]);
    assert fix_until_stable(g) == [["a", "b", "c"]];
}
