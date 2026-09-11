import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_wjhuang88__talos__317.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_symbol_graph(
    ["foo", "a", "b", "c"],
    [("foo", "a"), ("foo", "b"), ("a", "c"), ("b", "c")],
)
assert mod.reference_closure(g, "foo") == ["a", "b", "c", "foo"]
assert mod.reference_closure(g, "missing") == []
print("ok")
