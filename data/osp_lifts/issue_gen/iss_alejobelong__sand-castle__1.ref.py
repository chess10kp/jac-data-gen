"""Reference harness for iss_alejobelong__sand-castle__1."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_alejobelong__sand-castle__1.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_alejobelong__sand-castle__1.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_plan = _mod.load_plan
topological_levels = _mod.topological_levels
downstream_reach = _mod.downstream_reach
upstream_closure = _mod.upstream_closure
ready_slices = _mod.ready_slices
schedule_batches = _mod.schedule_batches
CycleError = _mod.CycleError

plan = load_plan(
    ["hub", "left", "right", "sink"],
    [("left", "sink"), ("right", "sink"), ("hub", "right"), ("hub", "left")],
)
assert downstream_reach(plan, "hub") == ["left", "right", "sink"]
assert upstream_closure(plan, "sink") == ["hub", "left", "right"]
assert topological_levels(plan) == [["hub"], ["left", "right"], ["sink"]]

plan = load_plan(["solo"], [])
assert downstream_reach(plan, "missing") == []
assert upstream_closure(plan, "missing") == []
assert ready_slices(plan, ["missing"]) == ["solo"]
try:
    load_plan(["a"], [("a", "b")])
    assert False, "expected KeyError for unknown downstream"
except KeyError:
    pass
try:
    load_plan(["a", "b"], [("ghost", "a")])
    assert False, "expected KeyError for unknown upstream"
except KeyError:
    pass

plan = load_plan(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
try:
    topological_levels(plan)
    assert False, "expected CycleError"
except CycleError:
    pass

plan = load_plan(
    ["a", "b", "c", "d"],
    [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
    max_concurrency=2,
)
assert schedule_batches(plan, []) == [["a"], ["b", "c"], ["d"]]
assert schedule_batches(plan, ["a"]) == [["b", "c"], ["d"]]
assert ready_slices(plan, ["a", "b"]) == ["c"]
plan2 = load_plan(["a", "b", "c"], [("a", "c")], max_concurrency=2)
assert schedule_batches(plan2, []) == [["a", "b"], ["c"]]

plan = load_plan(
    ["a", "b", "c", "d"],
    [("a", "c"), ("b", "c"), ("c", "d")],
)
assert ready_slices(plan, ["a"]) == ["b"]
assert ready_slices(plan, ["a", "b"]) == ["c"]
assert ready_slices(plan, ["a", "b", "c"]) == ["d"]
forest = load_plan(["p", "q", "r"], [("p", "q")], max_concurrency=2)
assert topological_levels(forest) == [["p", "r"], ["q"]]
assert schedule_batches(forest, []) == [["p", "r"], ["q"]]

empty = load_plan([], [])
assert topological_levels(empty) == []
assert ready_slices(empty) == []
assert schedule_batches(empty) == []
solo = load_plan(["only"], [])
assert downstream_reach(solo, "only") == []
assert upstream_closure(solo, "only") == []
assert ready_slices(solo) == ["only"]
assert schedule_batches(solo) == [["only"]]
assert topological_levels(solo) == [["only"]]

print("iss_alejobelong__sand-castle__1 ref OK")
print("iss_alejobelong__sand-castle__1 ref OK")
