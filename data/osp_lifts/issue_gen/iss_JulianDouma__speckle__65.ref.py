import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_JulianDouma__speckle__65",
    Path(__file__).with_name("iss_JulianDouma__speckle__65.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)
g = mod.load_beads(
    ["epic", "a", "b", "c"],
    [("a", "epic"), ("b", "epic"), ("c", "b")],
)
st = {"a": "closed", "b": "open", "c": "closed", "epic": "open"}
assert mod.direct_children(g, "epic") == ["a", "b"]
assert mod.subtree_ids(g, "epic") == ["a", "b", "c", "epic"]
rs = mod.rollup_stats(g, "epic", st)
assert rs["children_count"] == 3
assert rs["children_closed"] == 2
assert rs["progress"] == 66
assert rs["status_rollup"] == "in_progress"

g_d = mod.load_beads(
    ["hub", "left", "right", "leaf"],
    [("left", "hub"), ("right", "hub"), ("leaf", "left"), ("leaf", "right")],
)
assert mod.subtree_ids(g_d, "hub") == ["hub", "leaf", "left", "right"]
assert mod.direct_children(g, "missing") == []
assert mod.rollup_stats(g, "missing", {})["status_rollup"] == "unknown"
print("ok")
