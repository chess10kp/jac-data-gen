import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_msqd__harp__803",
    Path(__file__).with_name("iss_msqd__harp__803.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_graph([(0, 1), (1, 2)])
assert mod.topological_sort(g) == [0, 1, 2]
assert mod.reachable_from(g, 0) == [0, 1, 2]
assert mod.reachable_from(g, 2) == [2]

g2 = mod.load_graph([(0, 5), (5, 10), (0, 10)])
assert mod.topological_sort(g2) == [0, 5, 10]

g3 = mod.load_graph([(0, 1), (1, 0)])
assert mod.topological_sort(g3) == []
print("ok")
