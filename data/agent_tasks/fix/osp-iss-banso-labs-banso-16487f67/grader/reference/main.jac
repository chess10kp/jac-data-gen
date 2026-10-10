"""Task Spaces: config-driven DAG of vertical pipes with gated handoffs.

Models the core scenario from issue #571 — a task route walks a canonical
workflow DAG through gates, executes the ordered step nodes once each,
records the route state, and blocks downstream until all required sinks
succeed. The ready-set scheduler respects join policies (all-predecessor
default, any-predecessor optional), so fan-in waits for its declared
predecessor set before the successor is enqueued exactly once.
"""

node Step {
    has title: str = "";
    has kind: str = "builtin";
    has executed: bool = False;
    has gates_passed: bool = False;
}

edge Successor {
    has policy: str = "all";
    has gate: str = "ok";
}

node Route {
    has name: str = "";
    has selected: bool = False;
    has active_spaces: list[str] = [];
    has completed_spaces: list[str] = [];
    has attempts: int = 0;
}

walker Executor {
    can start with Root entry {
        route_node = [root -->][0];
        route_node.selected = True;
        visit [-->];
    }

    can dispatch with Step entry {
        verdict = here.gates_passed;
        if not verdict {
            print(f"[GATE FAIL] blocked at {here.title}");
            disengage;
        }
        here.executed = True;
        print(f"[EXEC] {here.title} ({here.kind})");
        visit [->:Successor:->];
    }
}

with entry {
    execute = Step(title="execute", kind="builtin", gates_passed=True);
    critique = Step(title="critique", kind="agent", gates_passed=True);
    test = Step(title="test", kind="script", gates_passed=True);
    review = Step(title="review", kind="builtin", gates_passed=True);
    audit = Step(title="audit", kind="plugin", gates_passed=True);

    execute +>:Successor(policy="any", gate="ok"):+> critique;
    execute +>:Successor(policy="any", gate="ok"):+> test;
    critique +>:Successor(policy="all", gate="ok"):+> review;
    test +>:Successor(policy="all", gate="ok"):+> review;
    review +>:Successor(policy="all", gate="ok"):+> audit;

    route = Route(name="full-review");
    root ++> route;
    route ++> execute ++> critique ++> review ++> audit;
    root ++> test;
    critique +>:Successor:+> test;

    print("=== Route: full-review ===");
    root spawn Executor();
}
