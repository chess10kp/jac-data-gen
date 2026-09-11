import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_laplace_924",
    Path(__file__).with_name("iss_SaltyPatron__Laplace__924.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_substrate(
    ["session", "trace", "circuit", "fold"],
    [("session", "trace"), ("trace", "circuit"), ("circuit", "fold")],
)
assert mod.n_hop_neighbors(g, "session", 1) == ["session", "trace"]
assert mod.reachable_within(g, "session", 3)

g_d = mod.load_substrate(
    ["hub", "left", "right", "bot"],
    [("right", "bot"), ("hub", "left"), ("left", "bot"), ("hub", "right")],
)
assert mod.n_hop_neighbors(g_d, "hub", 2) == ["bot", "hub", "left", "right"]
print("ok")
