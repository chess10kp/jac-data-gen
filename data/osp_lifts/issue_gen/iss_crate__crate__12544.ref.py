import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

EDGES = [("1", "2"), ("2", "3"), ("1", "4")]
CYCLE = [("a", "b"), ("b", "c"), ("c", "a")]

assert mod.recursive_cte_expand("1", EDGES) == ["1", "2", "3", "4"]
assert mod.cte_reachable("1", EDGES) == ["1", "2", "3", "4"]
assert mod.is_recursive_safe(EDGES) is True
assert mod.is_recursive_safe(CYCLE) is False
print("ok")
