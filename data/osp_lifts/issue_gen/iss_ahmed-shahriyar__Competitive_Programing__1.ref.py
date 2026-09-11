import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_ahmed-shahriyar__Competitive_Programing__1",
    Path(__file__).with_name("iss_ahmed-shahriyar__Competitive_Programing__1.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_graph([1, 2, 3, 4, 5], [(1, 2), (1, 3), (2, 4), (3, 5)])
assert mod.bfs_reachable(g, 1) == [2, 3, 4, 5]
assert mod.bfs_distance(g, 1, 5) == 2
assert mod.out_neighbors(g, 1) == [2, 3]

g_d = mod.load_graph([0, 1, 2, 3], [(0, 1), (0, 2), (1, 3), (2, 3)])
assert mod.bfs_reachable(g_d, 0) == [1, 2, 3]
print("ok")
