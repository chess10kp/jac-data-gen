import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("iss_filipexyz__ravi__389", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

NODES = ["build", "test", "deploy"]
EDGES = [("build", "test"), ("test", "deploy")]
CYCLE = [("a", "b"), ("b", "c"), ("c", "a")]

assert mod.eligible_targets(NODES, EDGES, {"build"}) == ["test"]
assert mod.eligible_targets(NODES, EDGES, {"build", "test"}) == ["deploy"]
assert mod.find_cycle_nodes(CYCLE) == ["a", "b", "c"]
assert mod.find_cycle_nodes(EDGES) == []
print("ok")
