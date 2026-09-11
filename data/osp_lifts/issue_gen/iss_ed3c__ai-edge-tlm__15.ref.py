import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod15",
    Path(__file__).with_name("iss_ed3c__ai-edge-tlm__15.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

dag = mod.load_dag(
    ["validate", "audit", "pytest", "packet"],
    [("packet", "validate"), ("packet", "audit"), ("validate", "pytest")],
)
assert mod.reachable_from(dag, "packet") == ["audit", "packet", "pytest", "validate"]
assert mod.validate_dag(dag) == []
assert mod.has_cycle(dag) is False

cyclic = mod.load_dag(["a", "b", "c"], [("a", "b"), ("b", "c"), ("c", "a")])
assert mod.has_cycle(cyclic) is True
assert len(mod.validate_dag(cyclic)) >= 1
print("ok")
