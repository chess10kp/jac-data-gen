import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_histdata_693",
    Path(__file__).with_name("iss_dmidlo__histdata_com-tools__693.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ls = mod.load_nodes(
    ["raw", "bar", "feat", "label"],
    [("bar", "raw"), ("feat", "bar"), ("label", "feat")],
)
assert mod.ancestor_hashes(ls, "label") == ["bar", "feat", "raw"]
assert mod.dependents_of(ls, "bar") == ["feat", "label"]
assert mod.is_acyclic(ls) is True

ls_cycle = mod.load_nodes(["a", "b"], [("a", "b"), ("b", "a")])
assert mod.is_acyclic(ls_cycle) is False

g_diamond = mod.load_nodes(
    ["root", "left", "right", "leaf"],
    [("left", "root"), ("right", "root"), ("leaf", "left"), ("leaf", "right")],
)
assert mod.ancestor_hashes(g_diamond, "leaf") == ["left", "right", "root"]
print("ok")
