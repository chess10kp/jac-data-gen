import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_nearbytes__nearbytes-files__2",
    Path(__file__).with_name("iss_nearbytes__nearbytes-files__2.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

STORE = mod.load_directory_tree([
    ["vol", "docs", "readme"],
    ["vol", "docs", "notes"],
    ["vol", "media", "cover"],
])
assert mod.breadcrumb(STORE, "readme") == ["vol", "docs", "readme"]
assert mod.subtree_ids(STORE, "docs") == ["docs", "notes", "readme"]
assert mod.breadcrumb(STORE, "missing") == []
print("ok")
