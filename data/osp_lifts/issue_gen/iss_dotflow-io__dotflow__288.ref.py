import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod288",
    Path(__file__).with_name("iss_dotflow-io__dotflow__288.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

dag = mod.load_dag(
    ["extract", "transform_a", "transform_b", "load"],
    [
        ("extract", "transform_a"),
        ("extract", "transform_b"),
        ("transform_a", "load"),
        ("transform_b", "load"),
    ],
)
levels = mod.topological_levels(dag)
assert levels[0] == ["extract"]
assert sorted(levels[1]) == ["transform_a", "transform_b"]
assert levels[2] == ["load"]
assert mod.remove_step(dag, "extract") == ["extract", "load", "transform_a", "transform_b"]
assert mod.active_steps(dag) == []

dag2 = mod.load_dag(["a", "b"], [("a", "b"), ("b", "a")])
try:
    mod.topological_levels(dag2)
    assert False, "expected CycleError"
except mod.CycleError:
    pass
print("ok")
