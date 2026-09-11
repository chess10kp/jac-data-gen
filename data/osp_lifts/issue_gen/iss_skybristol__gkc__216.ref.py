import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_gkc_216",
    Path(__file__).with_name("iss_skybristol__gkc__216.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ss = mod.load_seed(
    [("prop_parent", "property"), ("prop_child", "property"), ("item_leaf", "item")],
    [("item_leaf", "prop_child"), ("prop_child", "prop_parent")],
)
assert mod.dependency_order(ss) == ["prop_parent", "prop_child", "item_leaf"]
assert mod.detect_unresolved(ss) == []
assert mod.entity_kind(ss, "item_leaf") == "item"

ss_cycle = mod.load_seed([("a", "item"), ("b", "item")], [("a", "b"), ("b", "a")])
assert mod.dependency_order(ss_cycle) == []
assert mod.detect_unresolved(ss_cycle) == ["a", "b"]
print("ok")
