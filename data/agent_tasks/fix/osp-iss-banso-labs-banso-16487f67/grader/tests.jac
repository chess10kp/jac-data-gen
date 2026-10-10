import from main { Executor, Route, Step, Successor }
import io;
import from contextlib { redirect_stdout }

test "executes fanout and reaches the review handoff" {
    route = Route(name="full-review");
    execute = Step(title="execute", kind="builtin", gates_passed=True);
    critique = Step(title="critique", kind="agent", gates_passed=True);
    test_step = Step(title="test", kind="script", gates_passed=True);
    review = Step(title="review", kind="builtin", gates_passed=True);
    audit = Step(title="audit", kind="plugin", gates_passed=True);

    root ++> route;
    root ++> execute;
    execute +>:Successor(policy="any", gate="ok"):+> critique;
    execute +>:Successor(policy="any", gate="ok"):+> test_step;
    critique +>:Successor(policy="all", gate="ok"):+> review;
    test_step +>:Successor(policy="all", gate="ok"):+> review;
    review +>:Successor(policy="all", gate="ok"):+> audit;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Executor();
    }
    out = buf.getvalue();

    assert route.selected == True, f"route not selected: {route.selected}";
    assert execute.executed == True, f"execute not run: {execute.executed}";
    assert critique.executed == True, f"critique not run: {critique.executed}";
    assert test_step.executed == True, f"test not run: {test_step.executed}";
    assert review.executed == True, f"review not run: {review.executed}";
    assert audit.executed == True, f"audit not run: {audit.executed}";
    assert "[EXEC] review (builtin)" in out, f"review did not run: {out}";
    assert out.index("[EXEC] execute") < out.index("[EXEC] review"), f"wrong order: {out}";
}

test "failed gate blocks the downstream route" {
    route = Route(name="blocked");
    execute = Step(title="execute", kind="builtin", gates_passed=False);
    critique = Step(title="critique", kind="agent", gates_passed=True);
    test_step = Step(title="test", kind="script", gates_passed=True);
    review = Step(title="review", kind="builtin", gates_passed=True);
    audit = Step(title="audit", kind="plugin", gates_passed=True);

    root ++> route;
    root ++> execute;
    execute +>:Successor(policy="any", gate="ok"):+> critique;
    execute +>:Successor(policy="any", gate="ok"):+> test_step;
    critique +>:Successor(policy="all", gate="ok"):+> review;
    test_step +>:Successor(policy="all", gate="ok"):+> review;
    review +>:Successor(policy="all", gate="ok"):+> audit;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Executor();
    }
    out = buf.getvalue();

    assert route.selected == True, f"route not selected: {route.selected}";
    assert execute.executed == False, f"failed step executed: {execute.executed}";
    assert critique.executed == False, f"critique advanced: {critique.executed}";
    assert test_step.executed == False, f"test advanced: {test_step.executed}";
    assert review.executed == False, f"review advanced: {review.executed}";
    assert audit.executed == False, f"audit advanced: {audit.executed}";
    assert "[GATE FAIL] blocked at execute" in out, f"missing gate failure: {out}";
}

test "typed successor edges point from each step to its handoff" {
    route = Route(name="edge-check");
    execute = Step(title="execute", kind="builtin", gates_passed=True);
    audit = Step(title="audit", kind="plugin", gates_passed=True);

    root ++> route;
    root ++> execute;
    execute +>:Successor(policy="all", gate="ok"):+> audit;

    successors = [execute ->:Successor:->];
    reverse_successors = [audit ->:Successor:->];

    assert len(successors) == 1, f"successor count: {len(successors)}";
    assert audit in successors, f"audit is not a successor: {successors}";
    assert execute not in reverse_successors, f"edge points backwards: {reverse_successors}";
}
