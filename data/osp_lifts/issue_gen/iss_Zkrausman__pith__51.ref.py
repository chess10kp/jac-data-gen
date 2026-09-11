import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod51",
    Path(__file__).with_name("iss_Zkrausman__pith__51.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_portfolio(
    ["A", "B", "C", "D"],
    [("A", "B"), ("B", "C"), ("A", "D")],
    {"A": 10, "B": 50, "C": 30, "D": 20},
)
assert mod.planning_frontier(store, []) == ["A"]
assert mod.recommend_next(store, []) == "A"
assert mod.planning_frontier(store, ["A"]) == ["B", "D"]
assert mod.recommend_next(store, ["A"]) == "B"
assert mod.downstream_reach(store, "A") == ["B", "C", "D"]

store2 = mod.load_portfolio(["x", "y"], [("x", "y"), ("y", "x")], {})
try:
    mod.planning_frontier(store2, [])
    assert False, "expected CycleError"
except mod.CycleError:
    pass
print("ok")
