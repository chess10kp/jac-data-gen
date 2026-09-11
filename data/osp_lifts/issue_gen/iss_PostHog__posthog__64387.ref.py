import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_posthog_64387",
    Path(__file__).with_name("iss_PostHog__posthog__64387.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

fs = mod.load_flags(["parent", "child", "grand"], [("parent", "child"), ("child", "grand")])
assert mod.resolve_dependency_chain(fs, "parent") == ["child", "grand"]
assert mod.blast_radius_ids(fs, "parent") == ["child", "grand", "parent"]

fs_cycle = mod.load_flags(["a", "b"], [("a", "b"), ("b", "a")])
assert mod.resolve_dependency_chain(fs_cycle, "a") is None

g_diamond = mod.load_flags(
    ["root", "left", "right", "leaf"],
    [("root", "left"), ("root", "right"), ("left", "leaf"), ("right", "leaf")],
)
assert mod.resolve_dependency_chain(g_diamond, "root") == ["leaf", "left", "right"]
assert mod.missing_dependency(fs, "parent", "ghost") is True
print("ok")
