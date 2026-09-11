import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_petteriTeikari__music-attribution-scaffold__10",
    Path(__file__).with_name("iss_petteriTeikari__music-attribution-scaffold__10.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

CHAIN = mod.load_graph(
    ["a", "b", "c", "d"],
    [("a", "b"), ("b", "c"), ("c", "d")],
)
assert mod.neighbors_at_hop(CHAIN, "a", 1) == ["b"]
assert mod.neighbors_at_hop(CHAIN, "a", 2) == ["c"]
assert mod.neighbors_at_hop(CHAIN, "a", 3) == ["d"]
assert mod.all_reachable(CHAIN, "a", 3) == ["b", "c", "d"]

DIAMOND = mod.load_graph(
    ["root", "left", "right", "leaf"],
    [("root", "left"), ("root", "right"), ("left", "leaf"), ("right", "leaf")],
)
assert mod.all_reachable(DIAMOND, "root", 3) == ["leaf", "left", "right"]

CYCLE = mod.load_graph(
    ["x", "y", "z"],
    [("x", "y"), ("y", "z"), ("z", "x")],
)
assert mod.has_cycle(CYCLE) is True
assert mod.neighbors_at_hop(CYCLE, "x", 2) == ["z"]

assert mod.neighbors_at_hop(CHAIN, "missing", 1) == []
print("ok")
