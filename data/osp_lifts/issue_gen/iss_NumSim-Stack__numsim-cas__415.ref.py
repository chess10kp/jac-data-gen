"""Reference harness for NumSim-Stack/numsim-cas#415."""

import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "ns415", HERE / "iss_NumSim-Stack__numsim-cas__415.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
sys.modules["ns415"] = mod
spec.loader.exec_module(mod)

load_tree = mod.load_tree
subtree_hash = mod.subtree_hash
set_value = mod.set_value
add_child = mod.add_child
dirty_nodes = mod.dirty_nodes


def main() -> None:
    g = load_tree([("r", 1, None), ("a", 2, "r"), ("b", 3, "r"), ("c", 4, "a")])
    h0 = subtree_hash(g, "r")
    assert dirty_nodes(g) == []
    set_value(g, "b", 30)
    assert dirty_nodes(g) == ["b", "r"]
    h1 = subtree_hash(g, "r")
    assert h1 != h0
    add_child(g, "a", "d", 5)
    assert dirty_nodes(g) == ["a", "d", "r"]
    assert subtree_hash(g, "d") == 5
    assert subtree_hash(g, "missing") == 0
    print("ok")


if __name__ == "__main__":
    main()
