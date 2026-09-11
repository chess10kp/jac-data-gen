import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod7154",
    Path(__file__).with_name("iss_guevara__read-it-later__7154.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

tree = mod.load_adjacency([("root", None), ("a", "root"), ("b", "root"), ("a1", "a"), ("a2", "a")])
assert mod.adj_descendants(tree, "root") == ["a", "a1", "a2", "b"]
assert mod.adj_depth(tree, "a1") == 2
assert mod.adj_leaves(tree) == ["a1", "a2", "b"]
print("ok")
