"""Reference harness for iss_ClickHouse__ClickHouse__116016."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_ClickHouse__ClickHouse__116016.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
plan = _mod.build_issue_fixture(5)
assert _mod.dependency_closure(plan, "sq3") == ["sq1", "sq2", "sq3"]
assert _mod.materialize_cte(plan, "sq1") == [1, 2, 3, 4, 5]
assert _mod.materialize_cte(plan, "sq2") == [1, 2, 3, 4, 5]
try:
    _mod.materialize_cte(plan, "sq3")
    assert False
except _mod.TooDeepRecursion as exc:
    assert exc.cte == "sq3"
    assert exc.depth == 6

p2 = _mod.make_plan(8)
_mod.add_linear_cte(p2, "nums", 1, 3)
assert _mod.dependency_closure(p2, "nums") == ["nums"]
assert _mod.materialize_cte(p2, "nums") == [1, 2, 3]

p3 = _mod.make_plan(2)
_mod.add_linear_cte(p3, "short", 1, 10)
try:
    _mod.materialize_cte(p3, "short")
    assert False
except _mod.TooDeepRecursion as exc:
    assert exc.cte == "linear"
    assert exc.depth == 3

p4 = _mod.make_plan(5)
_mod.add_linear_cte(p4, "a", 1, 4)
_mod.add_projection_cte(p4, "b", "a")
assert _mod.dependency_closure(p4, "b") == ["a", "b"]
assert _mod.materialize_cte(p4, "b") == [1, 2, 3, 4]

assert _mod.dependency_closure(plan, "missing") == []
assert _mod.materialize_cte(plan, "missing") == []
print("iss_ClickHouse__ClickHouse__116016 ref OK")
