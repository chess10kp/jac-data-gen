"""Reference harness for borglab/GTDynamics#435."""

import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_borglab__GTDynamics__435",
    Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

LINKS = [
    ("base", "world", 0.0),
    ("shoulder", "base", 1.0),
    ("elbow", "shoulder", 0.5),
    ("wrist", "elbow", 0.25),
]
plan = mod.compile_traversal(LINKS)
assert mod.traversal_order(plan) == ["world", "base", "shoulder", "elbow", "wrist"]
angles = {"base": 0.1, "shoulder": 0.2, "elbow": -0.1, "wrist": 0.05}
pos = mod.forward_positions(plan, angles)
assert pos["wrist"] == 0.1 + 1.0 + 0.2 + 0.5 + (-0.1) + 0.25 + 0.05
queries = [("tip", "wrist"), ("mid", "shoulder")]
assert mod.query_point_positions(plan, angles, queries) == [
    ("mid", pos["shoulder"]),
    ("tip", pos["wrist"]),
]
print("ok")
