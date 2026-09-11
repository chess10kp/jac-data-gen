import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_leetcode_280",
    Path(__file__).with_name("iss_Stewie-pixel__claude-with-leetcode__280.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

n = 4
online = [True, True, True, True]
edges = [(0, 1, 5), (1, 2, 3), (2, 3, 4), (0, 2, 2)]
assert mod.max_min_path(n, online, edges, 20) == 3
net = mod.load_network(n, online, edges)
assert mod.feasible(net, 3, 20) is True
assert mod.feasible(net, 5, 20) is False
print("ok")
