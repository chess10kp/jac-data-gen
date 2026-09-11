import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_thingsflow_1",
    Path(__file__).with_name("iss_lirei-lab__thingsflow__1.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_twin_graph(
    ["t1", "t2", "t3", "t4"],
    {"t1": "acme", "t2": "acme", "t3": "acme", "t4": "other"},
    [("t1", "t2"), ("t2", "t3"), ("t3", "t4")],
)
assert mod.neighbors(store, "t1") == ["t2"]
assert mod.expand_relations(store, "t1", 1) == ["t1", "t2"]
assert mod.expand_relations(store, "t1", 2) == ["t1", "t2", "t3"]

store_d = mod.load_twin_graph(
    ["hub", "left", "right", "leaf"],
    {"hub": "t", "left": "t", "right": "t", "leaf": "t"},
    [("hub", "left"), ("hub", "right"), ("left", "leaf"), ("right", "leaf")],
)
assert mod.expand_relations(store_d, "hub", 3) == [
    "hub",
    "leaf",
    "left",
    "right",
]
print("ok")
