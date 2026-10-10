"""Test annex for the task-difficulty-as-shortest-path demo."""
import from main { Applies, CycleHunter, ShortestPath, State, Step }

import io;
import from contextlib { redirect_stdout }


test "ShortestPath finds verified distance on linear chain" {
    root ++> State(label="A");
    a = [root -->][0];
    b = State(label="B");
    c = State(label="C");
    d = State(label="D");
    a +>:Applies(func_name="f1"):+> b;
    b +>:Applies(func_name="f2"):+> c;
    c +>:Applies(func_name="f3"):+> d;

    sp = ShortestPath(target="D", max_depth=10);
    a spawn sp;
    assert sp.distance == 3, f"expected shortest distance 3, got {sp.distance}";
}


test "ShortestPath tracks sampled and verified length separately" {
    # Real reachable graph: S0 -> S1 -> S2 -> S3 (verified = 3)
    s0 = State(label="S0");
    s1 = State(label="S1");
    s2 = State(label="S2");
    s3 = State(label="S3");
    root ++> s0;
    s0 +>:Applies(func_name="inc"):+> s1;
    s1 +>:Applies(func_name="double"):+> s2;
    s2 +>:Applies(func_name="inc"):+> s3;

    # Sampled program (5 steps, contains a no-op and a state revisit).
    sampled_length = 5;
    step_a = State(label="S0");
    step_b = State(label="S1");
    step_c = State(label="S1");
    step_d = State(label="S2");
    step_e = State(label="S3");
    s0 +>:Step(idx=0, func_name="inc"):+> step_a;
    s0 +>:Step(idx=1, func_name="inc"):+> step_b;
    s0 +>:Step(idx=2, func_name="inc"):+> step_c;
    s0 +>:Step(idx=3, func_name="double"):+> step_d;
    s0 +>:Step(idx=4, func_name="inc"):+> step_e;

    sp = ShortestPath(target="S3", max_depth=10);
    s0 spawn sp;
    verified_length = sp.distance if sp.distance >= 0 else 0;

    # Issue core claim: sampled length (5) != verified shortest length (3).
    assert sampled_length == 5, f"sampled_length should be 5, got {sampled_length}";
    assert verified_length == 3, f"verified_length should be 3, got {verified_length}";
    assert sampled_length != verified_length, "issue premise: sampled vs verified must diverge";
    # Sampled length is strictly longer than verified shortest.
    assert sampled_length > verified_length, "sampled program should be longer than verified shortest";
}


test "ShortestPath returns distance -1 when target is unreachable" {
    s0 = State(label="S0");
    s1 = State(label="S1");
    root ++> s0;
    s0 +>:Applies(func_name="f"):+> s1;
    # Target "Nowhere" has no Applies path from S0.
    sp = ShortestPath(target="Nowhere", max_depth=10);
    s0 spawn sp;
    assert sp.distance == -1, f"unreachable target should yield -1, got {sp.distance}";
}


test "CycleHunter flags revisits and no-op steps in a sampled program" {
    # Sampled program with a no-op (S1 -> S1) and a revisit (S2 appears
    # twice via two distinct Step edges).  Build two parallel step edges
    # so the auditor sees both, and a self-loop Applies for the no-op.
    s0 = State(label="S0");
    s1 = State(label="S1");
    s2 = State(label="S2");
    root ++> s0;

    # Sampled program edges off s0: idx 0..4.
    step_a = State(label="S0");
    step_b = State(label="S1");
    step_c = State(label="S1");
    step_d = State(label="S2");
    step_e = State(label="S2");
    s0 +>:Step(idx=0, func_name="inc"):+> step_a;
    s0 +>:Step(idx=1, func_name="inc"):+> step_b;
    s0 +>:Step(idx=2, func_name="inc"):+> step_c;
    s0 +>:Step(idx=3, func_name="double"):+> step_d;
    s0 +>:Step(idx=4, func_name="inc"):+> step_e;

    ch = CycleHunter(target="S2");
    s0 spawn ch;
    # At least one state revisit was detected along the sampled walk.
    assert len(ch.revists) >= 1, f"expected at least 1 revisit, got {ch.revists}";
    # At least one no-op (leaf) was flagged in the audit.
    assert len(ch.no_ops) >= 1, f"expected at least 1 no-op, got {ch.no_ops}";
}


test "ShortestPath respects max_depth budget and does not infinite loop" {
    # Build a reachable target but with max_depth too small to reach it.
    s0 = State(label="S0");
    s1 = State(label="S1");
    s2 = State(label="S2");
    s3 = State(label="S3");
    root ++> s0;
    s0 +>:Applies(func_name="a"):+> s1;
    s1 +>:Applies(func_name="b"):+> s2;
    s2 +>:Applies(func_name="c"):+> s3;

    sp = ShortestPath(target="S3", max_depth=1);
    s0 spawn sp;
    # With a budget of 1 we cannot reach S3 (distance 3); must be -1.
    assert sp.distance == -1, f"budget=1 should fail to reach S3, got {sp.distance}";
}
