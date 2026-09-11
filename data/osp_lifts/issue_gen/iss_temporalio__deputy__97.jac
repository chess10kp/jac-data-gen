"""Composite-action inventory extraction, lifted to OSP.

Workflows and action manifests become Unit nodes; step references become
typed Uses edges; the per-path re-parsing recursion becomes a walker whose
claim map IS the once-per-resource memoization (the issue's fix: a manifest
parsed once is never parsed again, growth is linear in files). The parse
budget survives as explicit domain policy: an exhausted budget disengages
the walk with the partial parse list plus the budget_hit flag.
Ref: temporalio/deputy#97
"""
node Unit {
    has name: str;
}
edge Uses {}

glob DEFAULT_BUDGET: int = 64;

"""Loader handle: unit names resolve through this lookup map."""
obj Inv {
    has units: dict[str, Unit];

    def resolve(name: str) -> Unit | None {
        return self.units.get(name);
    }
}

"""Deterministic fresh-graph builder from a {kind: {name: [refs]}} spec."""
def load_inv(graph: dict) -> Inv {
    inv = Inv(units={});
    wf: dict[str, list[str]] = graph.get("workflow", {});
    mf: dict[str, list[str]] = graph.get("manifest", {});
    names: set[str] = set(wf.keys()) | set(mf.keys());
    for k in wf.keys() { names = names | set(wf[k]); }
    for k in mf.keys() { names = names | set(mf[k]); }
    for name in names {
        u = Unit(name=name);
        root ++> u;
        inv.units[name] = u;
    }
    for name in wf.keys() {
        for ref in wf[name] {
            if ref in inv.units {
                inv.units[name] +>:Uses:+> inv.units[ref];
            }
        }
    }
    for name in mf.keys() {
        for ref in mf[name] {
            if ref in inv.units {
                inv.units[name] +>:Uses:+> inv.units[ref];
            }
        }
    }
    return inv;
}

walker ExtractWalk {
    has claimed: dict[str, bool] = {};
    has parsed: list[str] = [];
    has budget_hit: bool = False;
    has budget: int = 64;

    can step with Unit entry {
        # Cycle/memo policy: one parse per resource regardless of path count.
        if here.name in self.claimed {
            skip;
        }
        # Budget policy: stop with the partial result already collected.
        if len(self.parsed) >= self.budget {
            self.budget_hit = True;
            disengage;
        }
        self.claimed[here.name] = True;
        self.parsed.append(here.name);
        visit [->:Uses:->] else { disengage; }
    }
}

"""Parse the composite-action graph at ``root``; one parse per unit."""
def extract(`root: str, graph: dict, budget: int = DEFAULT_BUDGET) -> dict {
    inv = load_inv(graph);
    r = inv.resolve(`root);
    if r is None {
        return {"parsed": [`root], "budget_hit": False};  # unknown root: lone unit, no refs
    }
    w = r spawn ExtractWalk(claimed={}, parsed=[], budget_hit=False, budget=budget);
    return {"parsed": w.parsed, "budget_hit": w.budget_hit};
}

"""How many units extraction parses (always 1 per unit post-fix)."""
def parse_count(`root: str, graph: dict, budget: int = DEFAULT_BUDGET) -> int {
    return len(extract(`root, graph, budget)["parsed"]);
}
