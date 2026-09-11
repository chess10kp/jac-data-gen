"""Guard: Gentleman-Programming/gentle-ai#2295."""

obj Workflow { has states: dict[str, StateNode] = {}; }
node StateNode { has name: str; has authority: str; }
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

test "workflow reachability" {
    w = load_workflow(
        [("verify", "auth-v1"), ("review", "auth-v2"), ("archive", "auth-v2")],
        [("verify", "review"), ("review", "archive")],
    );
    assert reachable_states(w, "verify") == ["archive", "review", "verify"];
    assert blocks_archive(w, "verify", "auth-v2") is True;
    assert blocks_archive(w, "archive", "auth-v2") is False;
}

test "verify refresh cycle reachable" {
    c = load_workflow(
        [("verify", "a"), ("review", "b"), ("verify_refresh", "c")],
        [("verify", "review"), ("review", "verify_refresh"), ("verify_refresh", "verify")],
    );
    assert reachable_states(c, "verify") == ["review", "verify", "verify_refresh"];
}

test "diamond adversarial" {
    d = load_workflow(
        [("start", "x"), ("left", "x"), ("right", "x"), ("end", "x")],
        [("start", "left"), ("start", "right"), ("left", "end"), ("right", "end")],
    );
    assert reachable_states(d, "start") == ["end", "left", "right", "start"];
}

test "unknown start tolerant" {
    w = load_workflow([("solo", "a")], []);
    assert reachable_states(w, "missing") == [];
}
