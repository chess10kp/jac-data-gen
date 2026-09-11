import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_hemia-labs__vell__29", Path(__file__).with_suffix(".py")
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ROWS = [
    ("root", None),
    ("electronics", "root"),
    ("phones", "electronics"),
    ("laptops", "electronics"),
    ("android", "phones"),
]

store = mod.CategoryStore()
store.load_all(ROWS)
assert store.find_descendant_ids("electronics") == ["android", "laptops", "phones"]
assert store.find_descendant_ids("phones") == ["android"]
assert store.find_descendant_ids("android") == []
assert store.find_descendant_ids("missing") == []

store2 = mod.CategoryStore()
store2.load_all([("a", None), ("b", "a"), ("c", "a"), ("d", "b"), ("e", "c")])
assert store2.find_descendant_ids("a") == ["b", "c", "d", "e"]
print("ok")
