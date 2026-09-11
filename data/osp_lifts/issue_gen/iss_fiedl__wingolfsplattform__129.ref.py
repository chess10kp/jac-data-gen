import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_fiedl__wingolfsplattform__129",
    Path(__file__).with_name("iss_fiedl__wingolfsplattform__129.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)
g = mod.load_dag(
    ["root", "a", "b", "c"],
    [("root", "a"), ("root", "b"), ("a", "c")],
)
assert mod.descendants(g, "root") == ["a", "b", "c", "root"]
assert mod.ancestors(g, "c") == ["c", "a", "root"]
assert mod.reach(g, "root", "c") is True
assert mod.reach(g, "c", "root") is False

g_d = mod.load_dag(
    ["hub", "left", "right", "leaf"],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
)
assert mod.descendants(g_d, "hub") == ["hub", "leaf", "left", "right"]
assert mod.descendants(g, "missing") == []
print("ok")
