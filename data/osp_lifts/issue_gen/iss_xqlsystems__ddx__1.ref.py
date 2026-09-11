import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_xqlsystems__ddx__1", Path(__file__).with_name("iss_xqlsystems__ddx__1.py")
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_plan(
    {"proj": "projection", "rcte": "recursive_cte", "dml": "dml", "scalar": "scalar_subquery"},
    {"root": ["proj", "rcte"], "rcte": ["rcte"]},
)
assert mod.can_substrait_emit(g, "proj")
assert not mod.can_substrait_emit(g, "rcte")
assert mod.recursive_reach(g, "root") == ["proj", "rcte"]
assert mod.recursive_reach(g, "missing") == []

g2 = mod.load_plan(
    {"a": "projection", "b": "projection", "c": "projection", "d": "projection"},
    {"a": ["b", "c"], "b": ["d"], "c": ["d"]},
)
assert mod.recursive_reach(g2, "a") == ["a", "b", "c", "d"]

print("ok")
