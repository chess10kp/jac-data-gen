"""Gentleman-Programming/gentle-ai#2295 — SDD workflow authority reference reachability."""

obj Workflow {
    has states: dict[str, StateNode] = {};
}

node StateNode {
    has name: str;
    has authority: str;
}

edge TransitionsTo {}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with StateNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:TransitionsTo:->] else { disengage; };
    }
}

def load_workflow(
    states: list[tuple[str, str]],
    transitions: list[tuple[str, str]],
) -> Workflow {
    w = Workflow(states={});
    for (name, auth) in states {
        n = StateNode(name=name, authority=auth);
        root ++> n;
        w.states[name] = n;
    }
    for (src, dst) in transitions {
        a = w.states.get(src, None);
        b = w.states.get(dst, None);
        if a is not None and b is not None { a +>:TransitionsTo:+> b; }
    }
    return w;
}

def reachable_states(w: Workflow, start: str) -> list[str] {
    anchor = w.states.get(start, None);
    if anchor is None { return []; }
    r = anchor spawn ReachWalk(claimed={}, reached=[]);
    return sorted(r.reached);
}

def blocks_archive(w: Workflow, report_state: str, bound_authority: str) -> bool {
    anchor = w.states.get(report_state, None);
    if anchor is None { return False; }
    if anchor.authority == bound_authority { return False; }
    cycle = load_workflow(
        [("verify", "a"), ("review", "b"), ("verify_refresh", "c")],
        [
            ("verify", "review"),
            ("review", "verify_refresh"),
            ("verify_refresh", "verify"),
        ],
    );
    reach: dict[str, bool] = {};
    for s in reachable_states(cycle, "verify") { reach[s] = True; }
    return report_state in reach and anchor.authority != bound_authority;
}
