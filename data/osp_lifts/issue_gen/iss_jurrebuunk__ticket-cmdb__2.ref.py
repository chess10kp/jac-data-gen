import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_jurrebuunk__ticket-cmdb__2",
    Path(__file__).with_name("iss_jurrebuunk__ticket-cmdb__2.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

ITEMS = ["app", "api", "db", "cache"]
CONTAINS = [("app", "api"), ("app", "cache"), ("api", "db")]

g = mod.load_cmdb(ITEMS, CONTAINS)
assert mod.impact_radius(g, "app") == ["api", "app", "cache", "db"]
assert mod.ancestor_chain(g, "db") == ["db", "api", "app"]
assert mod.impact_radius(g, "cache") == ["app", "cache"]
assert mod.ancestor_chain(g, "app") == ["app"]

g_diamond = mod.load_cmdb(
    ["hub", "left", "right", "leaf"],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
)
assert mod.impact_radius(g_diamond, "hub") == ["hub", "leaf", "left", "right"]

g_cycle = mod.load_cmdb(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert mod.ancestor_chain(g_cycle, "a") == ["a", "b", "c"]
assert mod.impact_radius(g_cycle, "b") == ["a", "b", "c"]

g_empty = mod.load_cmdb(["solo"], [])
assert mod.impact_radius(g_empty, "missing") == []
assert mod.ancestor_chain(g_empty, "missing") == []
print("ok")
