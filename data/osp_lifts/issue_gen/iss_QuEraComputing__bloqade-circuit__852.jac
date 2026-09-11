"""Call-graph analysis with once-per-callee visitation.

QuEraComputing/bloqade-circuit#852 lifted to OSP: functions become Function
archetypes and call sites become typed Calls edges. The per-path recursive
descent that re-analyzed each callee phi^max_depth times becomes a
budget-decrementing flood whose claim map analyzes every function exactly
once regardless of how many paths or cycles lead to it; the max_depth guard
still bounds traversal silently.
"""
node Function {
    has name: str;
}
edge Calls {}

"""Handle: function names resolve through this lookup map."""
obj CallGraph {
    has fns: dict[str, Function];

    def resolve(name: str) -> Function | None {
        return self.fns.get(name);
    }
}

def build_call_graph(functions: list[str], calls: list[tuple[str, str]]) -> CallGraph {
    g = CallGraph(fns={});
    for f in functions {
        n = Function(name=f);
        root ++> n;
        g.fns[f] = n;
    }
    for (caller, callee) in calls {
        a = g.fns.get(caller);
        b = g.fns.get(callee);
        if a is not None and b is not None {
            a +>:Calls:+> b;
        }
    }
    return g;
}

walker AnalyzeFlood {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_name: str = "";
    has budget: int = 0;
    has include_start: bool = False;

    can step with Function entry {
        if here.name in self.claimed {
            skip;
        }
        if self.include_start or here.name != self.start_name {
            self.reached.append(here.name);
        }
        self.claimed[here.name] = True;
        if self.budget <= 0 {
            skip;
        }
        for nb in [here ->:Calls:->] {
            nb spawn AnalyzeFlood(claimed=self.claimed, reached=self.reached,
                                  start_name=self.start_name,
                                  budget=self.budget - 1);
        }
    }
}

"""Sorted functions analyzed from ``entry`` within ``max_depth`` hops.

Each reachable function contributes one analysis unit even when several
call sites or cycles reach it; deeper callees return bottom.
"""
def analysis_units(g: CallGraph, entry_fn: str, max_depth: int) -> list[str] {
    st = g.resolve(entry_fn);
    if st is None or max_depth < 0 {
        return [];
    }
    w = st spawn AnalyzeFlood(start_name=entry_fn, budget=max_depth, include_start=True);
    return sorted(w.reached);
}

"""How many analyses the fixed engine performs (one per unique callee)."""
def frame_call_count(g: CallGraph, entry_fn: str, max_depth: int) -> int {
    return len(analysis_units(g, entry_fn, max_depth));
}

"""Recursive/mutually-recursive call graphs must not hang the pass."""
def terminates_on_recursion(g: CallGraph, entry_fn: str) -> bool {
    return len(analysis_units(g, entry_fn, 64)) > 0 or g.resolve(entry_fn) is not None;
}
