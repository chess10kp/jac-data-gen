import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_splendor-kernel__kernel__535",
    Path(__file__).with_name("iss_splendor-kernel__kernel__535.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

LINEAR = mod.load_change_graph(
    ["model", "tokenizer", "routenode", "agent"],
    [("model", "tokenizer"), ("model", "routenode"), ("routenode", "agent")],
)
assert mod.direct_dependents(LINEAR, "model") == ["routenode", "tokenizer"]
assert mod.blast_radius(LINEAR, "model") == ["agent", "model", "routenode", "tokenizer"]

CYCLE = mod.load_change_graph(
    ["a", "b", "c", "d"],
    [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d")],
)
assert mod.blast_radius(CYCLE, "a") == ["a", "b", "c", "d"]

DIAMOND = mod.load_change_graph(
    ["seed", "left", "right", "sink"],
    [("seed", "left"), ("seed", "right"), ("left", "sink"), ("right", "sink")],
)
assert mod.blast_radius(DIAMOND, "seed") == ["left", "right", "seed", "sink"]

assert mod.blast_radius(LINEAR, "missing") == []
print("ok")
