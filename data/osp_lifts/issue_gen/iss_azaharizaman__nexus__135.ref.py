import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod135",
    Path(__file__).with_name("iss_azaharizaman__nexus__135.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_org_tree(
    [("hq", None), ("branch-a", "hq"), ("branch-b", "hq"), ("dept-1", "branch-a"), ("cc-1", "dept-1")],
)
assert mod.ancestors_of(store, "cc-1") == ["hq", "branch-a", "dept-1", "cc-1"]
assert mod.descendants_of(store, "hq") == ["branch-a", "branch-b", "cc-1", "dept-1"]
assert mod.subtree_size(store, "branch-a") == 2
assert mod.leaf_orgs(store) == ["branch-b", "cc-1"]
print("ok")
