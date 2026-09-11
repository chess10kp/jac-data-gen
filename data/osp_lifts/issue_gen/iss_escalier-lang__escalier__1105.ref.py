import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod1105",
    Path(__file__).with_name("iss_escalier-lang__escalier__1105.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_classes([("A", "B"), ("B", "A")])
assert sorted(mod.extends_cycle_classes(store)) == ["A", "B"]
assert mod.is_valid_hierarchy(store) is False

store2 = mod.load_classes([("Child", "Base"), ("Base", None)])
assert mod.extends_chain(store2, "Child") == ["Child", "Base"]
assert mod.is_valid_hierarchy(store2) is True

store3 = mod.load_classes([("X", None)])
try:
    mod.add_extends(store3, "X", "X")
    assert False, "expected ExtendsCycleError"
except mod.ExtendsCycleError:
    pass
print("ok")
