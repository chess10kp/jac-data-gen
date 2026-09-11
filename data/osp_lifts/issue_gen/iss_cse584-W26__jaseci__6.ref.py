import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_jaseci_6",
    Path(__file__).with_name("iss_cse584-W26__jaseci__6.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_feed_graph(
    ["viewer", "a", "b", "c"],
    [("viewer", "a"), ("a", "b"), ("viewer", "c")],
    [("a", "p1"), ("b", "p2"), ("c", "p3"), ("viewer", "p0")],
)
assert mod.reachable_authors(g, "viewer") == ["a", "b", "c", "viewer"]
assert mod.feed_post_ids(g, "viewer") == ["p0", "p1", "p2", "p3"]
assert mod.chain_depth_ok(g, "viewer", 2)
assert mod.reachable_authors(g, "missing") == []

g_diamond = mod.load_feed_graph(
    ["hub", "left", "right", "leaf"],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    [("leaf", "only")],
)
assert mod.reachable_authors(g_diamond, "hub") == ["hub", "leaf", "left", "right"]
print("ok")
