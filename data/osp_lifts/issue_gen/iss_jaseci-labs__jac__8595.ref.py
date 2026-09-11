import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.GraphView()
for n in ["a", "b", "c", "d", "e"]:
    g.add_node(n)
for s, d in [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d"), ("d", "e")]:
    g.link(s, d)

assert g.neighbors_page("a", 0, 1) == ["b"]
assert g.neighbors_page("a", 1, 10) == ["c"]
assert g.neighborhood_cost("d") == 2
assert g.reachable("a") == ["a", "b", "c", "d", "e"]
assert g.reachable("missing") == []
print("ok")
