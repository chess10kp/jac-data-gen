"""ContextualWisdomLab/Orgmetra#89 — required gate closure on develop ruleset (OSP lift)."""

obj RulesetStore {
    has stamp: int = 0;
}

node Gate {
    has name: str;
}

edge Requires {}

walker PrereqWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for g in [-->][?:Gate] {
            if g.name == self.start {
                visit [g];
            }
        }
    }

    can step with Gate entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name != self.start {
            self.reached.append(here.name);
        }
        visit [->:Requires:->][?:Gate];
    }

    can finish with Root exit {
        report self.reached;
    }
}

def _wire(gates: list[str], requires: list[tuple[str, str]]) {
    mp: dict[str, Gate] = {};
    for nm in gates {
        if nm not in mp {
            g = Gate(name=nm);
            root ++> g;
            mp[nm] = g;
        }
    }
    for (gate, prereq) in requires {
        d = mp.get(gate, None);
        s = mp.get(prereq, None);
        if d is not None and s is not None {
            d +>:Requires:+> s;
        }
    }
}

def _gate(name: str) -> Gate | None {
    for g in [-->][?:Gate] {
        if g.name == name {
            return g;
        }
    }
    return None;
}

def load_ruleset(
    gates: list[str],
    requires: list[tuple[str, str]],
) -> RulesetStore {
    _wire(gates, requires);
    return RulesetStore(stamp=1);
}

def required_closure(store: RulesetStore, gate: str) -> list[str] {
    _ = store;
    if _gate(gate) is None {
        return [];
    }
    w = root spawn PrereqWalk(start=gate, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def merge_blockers(store: RulesetStore, failed: list[str]) -> list[str] {
    _ = store;
    blocked: list[str] = [];
    failed_set: dict[str, bool] = {};
    for f in failed {
        failed_set[f] = True;
    }
    for g in [-->][?:Gate] {
        need = required_closure(store, g.name);
        need = need + [g.name];
        hit = False;
        for req in need {
            if req in failed_set {
                hit = True;
            }
        }
        if hit {
            blocked.append(g.name);
        }
    }
    return sorted(blocked);
}
