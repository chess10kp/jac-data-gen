import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_iSparshP__Algorithms__3",
    Path(__file__).with_name("iss_iSparshP__Algorithms__3.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_adj_graph(
    ["1", "2", "3", "4"],
    [("1", "2"), ("1", "3"), ("2", "4")],
)
assert mod.adjacent_to(g, "1") == ["2", "3"]
assert mod.bfs_reach(g, "1") == ["1", "2", "3", "4"]

g_d = mod.load_adj_graph(
    ["hub", "left", "right", "leaf"],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
)
assert mod.bfs_reach(g_d, "hub") == ["hub", "leaf", "left", "right"]

g_c = mod.load_adj_graph(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert mod.adjacent_to(g_c, "b") == ["c"]
assert mod.bfs_reach(g_c, "a") == ["a", "b", "c"]

g_e = mod.load_adj_graph(["solo"], [])
assert mod.bfs_reach(g_e, "missing") == []
print("ok")
