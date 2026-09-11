import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_TheAlgorithms__Python__15071",
    Path(__file__).with_name("iss_TheAlgorithms__Python__15071.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_graph([(0, 1), (1, 2), (0, 2)])
assert mod.topological_sort(g) == [0, 1, 2]
assert mod.reachable_from(g, 0) == [0, 1, 2]

g_d = mod.load_graph([(0, 1), (0, 2), (1, 3), (2, 3)])
assert mod.reachable_from(g_d, 0) == [0, 1, 2, 3]
print("ok")
