import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

TREE = [("r", "a"), ("r", "b"), ("a", "c")]
CYCLE = [("a", "b"), ("b", "c"), ("c", "a")]

assert mod.children_of("r", TREE) == ["a", "b"]
assert mod.ancestors("c", TREE) == ["a", "r"]
assert mod.is_acyclic(TREE) is True
assert mod.is_acyclic(CYCLE) is False
assert mod.tree_closure("r", TREE) == ["a", "b", "c", "r"]
print("ok")
