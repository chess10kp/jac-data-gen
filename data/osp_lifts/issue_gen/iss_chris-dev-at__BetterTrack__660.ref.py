import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_chris-dev-at__BetterTrack__660",
    Path(__file__).with_name("iss_chris-dev-at__BetterTrack__660.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

NEST = mod.load_portfolios(
    ["D", "C", "A"],
    [("D", "C"), ("C", "A"), ("D", "A")],
)
assert mod.flattened_portfolios(NEST, "D") == ["A", "C", "D"]

CYCLE = mod.load_portfolios(["P", "Q"], [("P", "Q")])
assert mod.would_create_cycle(CYCLE, "Q", "P") is True
assert mod.would_create_cycle(CYCLE, "P", "Q") is False

DIAMOND = mod.load_portfolios(
    ["hub", "left", "right", "leaf"],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
)
assert mod.flattened_portfolios(DIAMOND, "hub") == ["hub", "leaf", "left", "right"]

DEPTH = mod.load_portfolios(
    ["a", "b", "c", "d", "e"],
    [("a", "b"), ("b", "c"), ("c", "d"), ("d", "e")],
    depth_cap=2,
)
assert mod.would_create_cycle(DEPTH, "e", "a") is False

assert mod.flattened_portfolios(NEST, "missing") == []
print("ok")
