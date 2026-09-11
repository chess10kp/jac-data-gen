import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_proletariat64__openwiki__7",
    Path(__file__).with_name("iss_proletariat64__openwiki__7.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

TREE = mod.load_reduce_tree(
    ["root", "L1a", "L1b", "L2a", "L2b", "leaf"],
    [("root", "L1a"), ("root", "L1b"), ("L1a", "L2a"), ("L1b", "L2b"), ("L2a", "leaf")],
)
assert mod.lineage(TREE, "leaf") == ["root", "L1a", "L2a", "leaf"]
assert mod.pending_leaves(TREE, ["root", "L1a", "L2a"]) == ["leaf"]
assert mod.pending_leaves(TREE, []) == []
assert mod.lineage(TREE, "ghost") == []
print("ok")
