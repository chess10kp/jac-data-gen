import importlib.util
from pathlib import Path

MOD = Path(__file__).with_suffix(".py").name
spec = importlib.util.spec_from_file_location(MOD, Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

LINE = [("a", "b"), ("b", "c")]
DIAMOND = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")]
CYCLE = [("a", "b"), ("b", "c"), ("c", "a")]

assert mod.bfs_order(LINE, "a") == ["a", "b", "c"]
assert mod.dfs_preorder(LINE, "a") == ["a", "b", "c"]
assert mod.bfs_order(DIAMOND, "a") == ["a", "b", "c", "d"]
assert sorted(mod.dfs_preorder(DIAMOND, "a")) == ["a", "b", "c", "d"]
assert mod.reachable(CYCLE, "a") == ["a", "b", "c"]
assert mod.bfs_order([], "x") == []
print("ok")
