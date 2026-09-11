import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod7153",
    Path(__file__).with_name("iss_guevara__read-it-later__7153.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_nested_set(
    [
        ("root", 1, 10, None),
        ("a", 2, 5, "root"),
        ("b", 6, 9, "root"),
        ("a1", 3, 4, "a"),
    ],
)
assert mod.nested_subtree(store, "root") == ["a", "a1", "b", "root"]
assert mod.nested_subtree(store, "a") == ["a", "a1"]
assert mod.nested_ancestors(store, "a1") == ["root", "a"]
assert mod.nested_depth(store, "a1") == 2
assert mod.contains_node(store, "a", "a1") is True
assert mod.contains_node(store, "b", "a1") is False
print("ok")
