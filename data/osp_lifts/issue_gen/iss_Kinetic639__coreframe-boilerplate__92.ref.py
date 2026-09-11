import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_kinetic_92",
    Path(__file__).with_name("iss_Kinetic639__coreframe-boilerplate__92.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

STORE = mod.load_categories(
    ["root", "electronics", "phones", "laptops"],
    [("root", "electronics"), ("electronics", "phones"), ("electronics", "laptops")],
    [("root", 0), ("electronics", 1), ("phones", 2), ("laptops", 2)],
)
assert mod.is_descendant(STORE, "phones", "electronics") is True
assert mod.is_descendant(STORE, "electronics", "phones") is False
assert mod.get_ancestors(STORE, "phones") == ["electronics", "root"]

STORE = mod.load_categories(
    ["root", "electronics", "phones", "laptops"],
    [("root", "electronics"), ("electronics", "phones"), ("electronics", "laptops")],
    [("root", 0), ("electronics", 0), ("phones", 0), ("laptops", 0)],
)
assert mod.update_children_levels(STORE, "root", 0) == ["electronics", "laptops", "phones"]

assert mod.is_descendant(STORE, "missing", "root") is False
print("ok")
