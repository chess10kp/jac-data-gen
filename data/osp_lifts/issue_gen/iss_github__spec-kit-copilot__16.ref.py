"""Reference harness for iss_github__spec-kit-copilot__16."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_github__spec-kit-copilot__16.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import pathlib

_here = pathlib.Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location(
    "iss_github__spec-kit-copilot__16",
    _here / "iss_github__spec-kit-copilot__16.py",
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

fresh_stack_store = _mod.fresh_stack_store
register_feature = _mod.register_feature
add_dependency_edge = _mod.add_dependency_edge
direct_dependents = _mod.direct_dependents
reachable_dependents = _mod.reachable_dependents
cascade_mark_stacked = _mod.cascade_mark_stacked
stack_report = _mod.stack_report

s = fresh_stack_store()
assert isinstance(s, dict)
assert set(s.keys()) == {"features", "deps", "rev", "nodes", "stacked", "lanes"}

s = fresh_stack_store()
register_feature("4210", s)
register_feature("feat_a", s)
register_feature("feat_b", s)
register_feature("shared", s)
add_dependency_edge("4210", "feat_a", s)
add_dependency_edge("4210", "feat_b", s)
add_dependency_edge("feat_a", "shared", s)
add_dependency_edge("feat_b", "shared", s)
got = reachable_dependents("4210", s)
assert got == ["feat_a", "shared", "feat_b"]
assert direct_dependents("4210", s) == ["feat_a", "feat_b"]
shared_count = 0
for fid in got:
    if fid == "shared":
        shared_count += 1
assert shared_count == 1

s1 = fresh_stack_store()
register_feature("4210", s1)
register_feature("feat_a", s1)
register_feature("feat_b", s1)
register_feature("shared", s1)
add_dependency_edge("4210", "feat_b", s1)
add_dependency_edge("feat_b", "shared", s1)
add_dependency_edge("4210", "feat_a", s1)
add_dependency_edge("feat_a", "shared", s1)

s2 = fresh_stack_store()
register_feature("4210", s2)
register_feature("feat_a", s2)
register_feature("feat_b", s2)
register_feature("shared", s2)
add_dependency_edge("4210", "feat_a", s2)
add_dependency_edge("feat_a", "shared", s2)
add_dependency_edge("4210", "feat_b", s2)
add_dependency_edge("feat_b", "shared", s2)
assert reachable_dependents("4210", s1) == reachable_dependents("4210", s2)

s = fresh_stack_store()
register_feature("4210", s)
caught = False
try:
    direct_dependents("missing", s)
except KeyError:
    caught = True
assert caught
caught2 = False
try:
    add_dependency_edge("4210", "missing", s)
except KeyError:
    caught2 = True
assert caught2

s = fresh_stack_store()
register_feature("4210", s)
register_feature("4212", s)
add_dependency_edge("4210", "4212", s)
marked = cascade_mark_stacked("4210", s)
assert marked == ["4210", "4212"]
rep = stack_report("4210", s)
assert rep["stacked"] is True
assert rep["stack_layer_count"] == 2

s = fresh_stack_store()
register_feature("4210", s)
register_feature("4212", s)
add_dependency_edge("4210", "4212", s)
rep = stack_report("4210", s)
assert rep["direct"] == ["4212"]
assert rep["reach"] == ["4212"]
assert rep["reach_count"] == 1
assert rep["stacked"] is False
assert rep["stack_layer_count"] == 0
print("iss_github__spec-kit-copilot__16 ref OK")
