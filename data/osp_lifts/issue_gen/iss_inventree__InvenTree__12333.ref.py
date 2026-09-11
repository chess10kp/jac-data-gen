import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_12333",
    Path(__file__).with_name("iss_inventree__InvenTree__12333.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_mptt_tree(
    ["root", "a", "b", "c"],
    [("root", None), ("a", "root"), ("b", "a"), ("c", "b")],
)
assert mod.get_descendants(store, "root") == ["a", "b", "c", "root"]
assert mod.get_ancestors(store, "c") == ["a", "b", "root"]
assert mod.subtree_size(store, "a") == 3

store_d = mod.load_mptt_tree(
    ["hub", "left", "right", "leaf"],
    [("hub", None), ("left", "hub"), ("right", "hub"), ("leaf", "left")],
)
assert mod.get_descendants(store_d, "hub") == ["hub", "leaf", "left", "right"]
assert mod.get_descendants(store_d, "missing") == []
print("ok")
