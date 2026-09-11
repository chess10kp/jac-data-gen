import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod78",
    Path(__file__).with_name("iss_agent-pipe-shared__agent-pipeline__78.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

estate = mod.load_estate(
    [("README.md", "journey"), ("setup.md", "task"), ("lifecycle.md", "journey"), ("archive/old.md", "evidence")],
    [("README.md", "setup.md"), ("README.md", "lifecycle.md"), ("setup.md", "lifecycle.md")],
)
assert mod.reachable_docs(estate, "README.md") == ["README.md", "lifecycle.md", "setup.md"]
assert mod.orphan_docs(estate, ["README.md"]) == ["archive/old.md"]
layers = mod.journey_layers(estate)
assert layers[0] == ["README.md", "archive/old.md"]
assert layers[1] == ["setup.md"]
assert layers[2] == ["lifecycle.md"]

estate2 = mod.load_estate([("a", "x"), ("b", "x")], [("a", "b"), ("b", "a")])
assert mod.reference_cycle_nodes(estate2) == ["a"]
print("ok")
