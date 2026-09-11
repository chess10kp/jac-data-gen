import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

t = mod.CategoryTree()
for c in ["root", "electronics", "phones", "android", "ios"]:
    t.add_category(c)
t.add_child("root", "electronics")
t.add_child("electronics", "phones")
t.add_child("phones", "android")
t.add_child("phones", "ios")

assert t.descendants("phones") == ["android", "ios", "phones"]
assert t.ancestors("android") == ["electronics", "phones", "root"]
assert t.find_cycle() == []
assert t.descendants("missing") == []

t2 = mod.CategoryTree()
for c in ["a", "b", "c"]:
    t2.add_category(c)
t2.add_child("a", "b")
t2.add_child("b", "c")
t2.add_child("c", "a")
cyc = t2.find_cycle()
assert len(cyc) >= 2
assert sorted(set(cyc)) == ["a", "b", "c"]
print("ok")
