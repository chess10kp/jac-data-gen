import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_benediktms__synapse__40",
    Path(__file__).with_name("iss_benediktms__synapse__40.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

HUB = mod.load_memory_graph(
    ["m1", "m2", "m3", "m4", "m5"],
    [("m1", "m2"), ("m1", "m3"), ("m2", "m4"), ("m3", "m5")],
)
assert mod.subgraph_nodes(HUB, ["m1"], 10) == ["m1", "m2", "m3", "m4", "m5"]
assert len(mod.subgraph_nodes(HUB, ["m1"], 3)) == 3
assert mod.truncated(HUB, ["m1"], 3) is True

CYCLE = mod.load_memory_graph(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert mod.subgraph_nodes(CYCLE, ["a"], 5) == ["a", "b", "c"]

DIAMOND = mod.load_memory_graph(
    ["seed", "left", "right", "leaf"],
    [("right", "leaf"), ("seed", "left"), ("left", "leaf"), ("seed", "right")],
)
assert mod.subgraph_nodes(DIAMOND, ["seed"], 10) == ["leaf", "left", "right", "seed"]

assert mod.subgraph_nodes(HUB, ["missing"], 5) == []
print("ok")
