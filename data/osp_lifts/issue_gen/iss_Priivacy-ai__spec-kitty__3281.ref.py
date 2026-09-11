import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod3281",
    Path(__file__).with_name("iss_Priivacy-ai__spec-kitty__3281.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_lanes(
    ["lane-a", "lane-b", "lane-c"],
    [("lane-a", "lane-b"), ("lane-a", "lane-c"), ("lane-b", "lane-c")],
)
assert mod.dependency_closure(store, "lane-c") == ["lane-a", "lane-b"]
assert mod.missing_dependencies(store, "lane-c") == ["lane-a", "lane-b"]
mod.mark_merged(store, "lane-a")
assert mod.missing_dependencies(store, "lane-c") == ["lane-b"]
assert mod.is_ancestor_merged(store, "lane-c") is False
mod.mark_merged(store, "lane-b")
assert mod.is_ancestor_merged(store, "lane-c") is True
print("ok")
