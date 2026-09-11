"""Reference harness: exercises every public function of iss_temporalio__deputy__97."""
import importlib

mod = importlib.import_module("iss_temporalio__deputy__97")
extract = mod.extract
parse_count = mod.parse_count

# Diamond fan-out: shared manifest referenced from many paths parses once.
graph = {
    "workflow": {"root": ["shared", "shared", "build"], "build": ["shared", "leaf"]},
    "manifest": {"shared": ["leaf"], "leaf": []},
}
res = extract("root", graph)
assert sorted(res["parsed"]) == ["build", "leaf", "root", "shared"]
assert res["budget_hit"] is False
assert parse_count("root", graph) == 4  # linear in files, not fanout^depth

# Exponential shape: deep fan-out of depth 6 with branching 3 (732 paths)
# still parses each of its 13 units exactly once.
fan = {"workflow": {"top": ["f0", "f1", "f2"]}, "manifest": {}}
for i in range(3):
    fan["manifest"][f"f{i}"] = [f"f{i}0", f"f{i}1"]
    for j in range(2):
        fan["manifest"][f"f{i}{j}"] = ["g"]
fan["manifest"]["g"] = []
res = extract("top", fan)
assert sorted(res["parsed"]) == ["f0", "f00", "f01", "f1", "f10", "f11", "f2", "f20", "f21", "g", "top"]
assert res["budget_hit"] is False

# Cyclic manifest references terminate via the once-per-resource set.
cyc = {"workflow": {"w": ["a"]}, "manifest": {"a": ["b"], "b": ["a"]}}
res = extract("w", cyc)
assert sorted(res["parsed"]) == ["a", "b", "w"]
assert res["budget_hit"] is False

# Budget exhausted: partial result plus the budget_hit flag. Order-independent
# budget points only (traversal order is unspecified): 0 parses, root only,
# or the full four-unit graph.
res = extract("root", graph, budget=0)
assert res["parsed"] == [] and res["budget_hit"] is True
res = extract("root", graph, budget=1)
assert res["parsed"] == ["root"] and res["budget_hit"] is True
res = extract("root", graph, budget=4)
assert sorted(res["parsed"]) == ["build", "leaf", "root", "shared"]
assert res["budget_hit"] is False

# Unknown root: lone unit, no refs (graph lookups tolerate missing names).
res = extract("ghost", {"workflow": {}, "manifest": {}})
assert res["parsed"] == ["ghost"] and res["budget_hit"] is False

print("iss_temporalio__deputy__97 ref OK")
