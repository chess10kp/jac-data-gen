import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod6",
    Path(__file__).with_name("iss_gaurav-chaurasia__blog__6.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_graph(
    ["A", "B", "C", "D", "E"],
    [("A", "B"), ("B", "C"), ("A", "D"), ("D", "E")],
)
assert mod.bfs_reachable(g, "A") == ["A", "B", "C", "D", "E"]
assert mod.has_path(g, "C", "E") is True
assert mod.has_path(g, "C", "X") is False
assert mod.component_size(g, "A") == 5

g2 = mod.load_graph(
    ["root", "left", "right", "leaf"],
    [("root", "left"), ("root", "right"), ("left", "leaf"), ("right", "leaf")],
)
assert mod.bfs_reachable(g2, "root") == ["leaf", "left", "right", "root"]
print("ok")
