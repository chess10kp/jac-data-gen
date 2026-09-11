"""Guard: vllm-project/vllm-omni#6296."""

import from iss_vllm-project__vllm-omni__6296 {
    NpuPlan,
}

test "npu vocoder chain impact and claim gates" {
    items = ["C", "B", "A", "D", "E1"];
    edges = [("C", "B"), ("C", "A"), ("B", "A"), ("A", "E1")];
    plan = NpuPlan();
    plan.load(items, edges);
    assert plan.downstream_impact("C") == ["A", "B", "E1"];
    assert plan.downstream_impact("B") == ["A", "E1"];
    assert plan.downstream_impact("D") == [];
    assert plan.eligible_claims(set()) == ["C", "D"];
    assert plan.eligible_claims({"C"}) == ["B", "D"];
    assert plan.eligible_claims({"C", "B", "A"}) == ["D", "E1"];
}

test "diamond adversarial edge order" {
  # merge sink wired before hub arms — stresses revisit ordering
    plan = NpuPlan();
    plan.load(
        ["hub", "left", "right", "sink"],
        [("left", "sink"), ("right", "sink"), ("hub", "left"), ("hub", "right")],
    );
    assert plan.downstream_impact("hub") == ["left", "right", "sink"];
}

test "cycle claim-map not disengage" {
    plan = NpuPlan();
    plan.load(
        ["p", "a", "b", "d"],
        [("p", "a"), ("a", "b"), ("b", "p"), ("b", "d")],
    );
    assert plan.downstream_impact("p") == ["a", "b", "d"];
}

test "unknown stage tolerance" {
    plan = NpuPlan();
    plan.load(["only"], []);
    assert plan.downstream_impact("ghost") == [];
}
