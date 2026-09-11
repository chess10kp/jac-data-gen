import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_explorers_6",
    Path(__file__).with_name("iss_tingard__explorers__6.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_tree([0, 1, 2, 3, 4], [(1, 0), (2, 1), (3, 2), (4, 3)])
assert mod.get_parent_chain(g, 4) == [4, 3, 2, 1, 0]
assert mod.neighborhood_ancestors(g, [2, 4]) == [0, 1, 2, 3, 4]
assert mod.safe_rewire(g, 5, 1, 2) is False
g2 = mod.load_tree([0, 1, 2, 3, 10], [(1, 0), (2, 1), (3, 2), (10, 1)])
assert mod.safe_rewire(g2, 10, 1, 3) is True
assert mod.get_parent_chain(g2, 3) == [3, 10, 1, 0]
print("ok")
