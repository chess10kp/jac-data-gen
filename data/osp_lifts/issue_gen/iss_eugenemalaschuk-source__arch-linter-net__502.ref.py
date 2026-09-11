import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_eugenemalaschuk-source__arch-linter-net__502.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_shape_graph(
    ["a", "b", "c", "d"],
    [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
)
assert mod.reachable_from(g, "a") == ["a", "b", "c", "d"]
assert mod.shape_stats(g, ["a", "d"]) == {"a": 4, "d": 1}
print("ok")
