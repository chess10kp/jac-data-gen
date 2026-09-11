#!/usr/bin/env python3
"""Reference harness for iss_vllm-project__vllm-omni__6296.py"""

import importlib.util
from pathlib import Path

_MOD = Path(__file__).with_name("iss_vllm-project__vllm-omni__6296.py")
spec = importlib.util.spec_from_file_location(
    "iss_vllm-project__vllm-omni__6296", _MOD
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ITEMS = ["C", "B", "A", "D", "E1"]
EDGES = [("C", "B"), ("C", "A"), ("B", "A"), ("A", "E1")]

plan = mod.NpuPlan()
plan.load(ITEMS, EDGES)

assert plan.downstream_impact("C") == ["A", "B", "E1"]
assert plan.downstream_impact("B") == ["A", "E1"]
assert plan.downstream_impact("D") == []
assert plan.downstream_impact("missing") == []

assert plan.eligible_claims(set()) == ["C", "D"]
assert plan.eligible_claims({"C"}) == ["B", "D"]
assert plan.eligible_claims({"C", "B"}) == ["A", "D"]
assert plan.eligible_claims({"C", "B", "A"}) == ["D", "E1"]
assert plan.eligible_claims({"C", "B", "A", "D", "E1"}) == []

# diamond: hub fans to two arms then merge
diamond = mod.NpuPlan()
diamond.load(
    ["hub", "left", "right", "sink"],
    [("hub", "left"), ("hub", "right"), ("left", "sink"), ("right", "sink")],
)
assert diamond.downstream_impact("hub") == ["left", "right", "sink"]

# cycle: revisit must not truncate closure
cycle = mod.NpuPlan()
cycle.load(
    ["p", "a", "b", "d"],
    [("p", "a"), ("a", "b"), ("b", "p"), ("b", "d")],
)
assert cycle.downstream_impact("p") == ["a", "b", "d"]

print("ok")
