import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_abdeslam-menacere__ModelTree__39",
    Path(__file__).with_name("iss_abdeslam-menacere__ModelTree__39.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

b = mod.load_lineage(
    ["root", "a", "b", "c", "d"],
    [("root", "a"), ("a", "b"), ("a", "c"), ("b", "d")],
)
assert mod.trail_nodes(b, "a") == ["a", "b", "c", "root"]
assert mod.trail_nodes(b, "d") == ["a", "b", "d", "root"]
assert mod.sibling_nodes(b, "b") == ["c"]
assert mod.sibling_nodes(b, "root") == []
assert mod.trail_nodes(b, "missing") == []

print("ok")
