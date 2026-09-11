"""EffortlessMetrics/perl-lsp-swarm#7161 — bounded subpattern call reachability (OSP lift)."""

obj PatternStore { has patterns: dict[str, Pattern] = {}; }

node Pattern { has pid: str; }
edge Calls {}

walker CallReach {
    has budget: int = 0;
    has depth: int = 0;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Pattern entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.hits.append(here.pid);
        if self.depth >= self.budget { disengage; }
        old = self.depth;
        self.depth = self.depth + 1;
        for callee in [here ->:Calls:->][?:Pattern] {
            visit [callee];
        }
        self.depth = old;
    }
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has on_stack: dict[str, bool] = {};
    has found: bool = False;

    can step with Pattern entry {
        if self.found { disengage; }
        if here.pid in self.on_stack {
            self.found = True;
            disengage;
        }
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.on_stack[here.pid] = True;
        visit [->:Calls:->] else {
            del self.on_stack[here.pid];
            disengage;
        };
    }
}

def load_patterns(
    patterns: list[str],
    calls: list[tuple[str, str]],
) -> PatternStore {
    ps = PatternStore();
    for pid in patterns {
        if pid not in ps.patterns {
            p = Pattern(pid=pid);
            root ++> p;
            ps.patterns[pid] = p;
        }
    }
    for (src, dst) in calls {
        a = ps.patterns.get(src, None);
        b = ps.patterns.get(dst, None);
        if a is not None and b is not None { a +>:Calls:+> b; }
    }
    return ps;
}

def call_reachable(ps: PatternStore, start: str, depth_budget: int) -> list[str] {
    anchor = ps.patterns.get(start, None);
    if anchor is None or depth_budget < 0 { return []; }
    w = anchor spawn CallReach(budget=depth_budget, depth=0, claimed={}, hits=[]);
    return sorted(w.hits);
}

def budget_exhausted(ps: PatternStore, start: str, depth_budget: int) -> bool {
    reach = call_reachable(ps, start, depth_budget);
    full = call_reachable(ps, start, len(ps.patterns) + 5);
    return len(reach) < len(full);
}

def mutual_cycle_detected(ps: PatternStore, start: str) -> bool {
    anchor = ps.patterns.get(start, None);
    if anchor is None { return False; }
    w = anchor spawn CycleProbe(claimed={}, on_stack={}, found=False);
    return w.found;
}
