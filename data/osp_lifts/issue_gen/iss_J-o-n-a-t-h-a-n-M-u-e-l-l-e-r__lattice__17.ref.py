import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_lattice_17",
    Path(__file__).with_name("iss_J-o-n-a-t-h-a-n-M-u-e-l-l-e-r__lattice__17.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_graph(["a", "b", "c", "d", "e"], [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d"), ("d", "e")])
sccs = mod.strongly_connected_components(g)
assert sccs == [["d"], ["e"], ["a", "b", "c"]]
cycle = mod.shortest_cycle_path(g, ["a", "b", "c"])
assert cycle[0] == cycle[-1]
assert len(cycle) >= 3

g2 = mod.load_graph(["x", "y"], [("x", "y")])
assert mod.strongly_connected_components(g2) == [["x"], ["y"]]
print("ok")
