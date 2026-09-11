import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_djm204__frankenbeast__4122",
    Path(__file__).with_name("iss_djm204__frankenbeast__4122.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

DAG = mod.load_plan(
    ["a", "b", "c", "d"],
    [("b", "a"), ("c", "b"), ("d", "c")],
)
assert mod.validate_plan(DAG) == ["a", "b", "c", "d"]
assert mod.build_subgraph(DAG, ["b", "c", "d"]) == ["b", "c", "d"]

CYCLIC = mod.load_plan(
    ["x", "y", "z"],
    [("x", "y"), ("y", "z"), ("z", "x")],
)
try:
    mod.validate_plan(CYCLIC)
    raise AssertionError("expected cycle")
except mod.CyclicDependencyError:
    pass

DIAMOND = mod.load_plan(
    ["root", "left", "right", "merge"],
    [("left", "root"), ("right", "root"), ("merge", "left"), ("merge", "right")],
)
assert mod.validate_plan(DIAMOND) == ["root", "left", "right", "merge"]

assert mod.build_subgraph(DAG, ["missing"]) == []
print("ok")
