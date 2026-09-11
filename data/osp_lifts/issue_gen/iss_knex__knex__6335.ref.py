import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_graph(["a", "b", "c", "d"], [("a", "b"), ("a", "c"), ("b", "d")])
assert g.closure("a") == ["a", "b", "c", "d"]
assert g.closure("missing") == []
cyc = mod.load_graph(["x", "y", "z"], [("x", "y"), ("y", "z"), ("z", "x")])
assert cyc.closure("x") is None
assert cyc.has_cycle() is True
print("ok")
