import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_pasca-l__book-reading__9",
    Path(__file__).with_name("iss_pasca-l__book-reading__9.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

t = mod.load_tree(
    ["root", "a", "b", "c"],
    [("root", None), ("a", "root"), ("b", "a"), ("c", "b")],
)
assert mod.tree_descendants(t, "root") == ["a", "b", "c", "root"]
assert mod.ancestor_path(t, "c") == ["c", "b", "a", "root"]

t_d = mod.load_tree(
    ["hub", "left", "right", "leaf"],
    [
        ("hub", None),
        ("left", "hub"),
        ("right", "hub"),
        ("leaf", "left"),
    ],
)
# leaf also reachable via right in a DAG-like bug table — only tree edges here
assert mod.tree_descendants(t_d, "hub") == ["hub", "leaf", "left", "right"]

t_e = mod.load_tree(["solo"], [("solo", None)])
assert mod.tree_descendants(t_e, "missing") == []
assert mod.ancestor_path(t_e, "missing") == []
print("ok")
