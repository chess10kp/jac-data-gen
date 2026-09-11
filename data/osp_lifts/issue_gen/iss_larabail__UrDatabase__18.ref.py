import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_urdb_18",
    Path(__file__).with_name("iss_larabail__UrDatabase__18.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_library(
    ["lib", "a", "b", "c", "link"],
    [("lib", "a"), ("a", "b"), ("b", "c"), ("c", "link"), ("link", "a")],
    reparse_points=["link"],
)
assert mod.scan_subdirs(g, "lib") == ["a", "b", "c", "lib"]
assert mod.scan_subdirs(g, "lib", follow_links=True) == ["a", "b", "c", "lib", "link"]
assert mod.reachable_without_guard(g, "lib") == ["a", "b", "c", "lib", "link"]
print("ok")
