import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_eugenemalaschuk-source__arch-linter-net__123",
    Path(__file__).with_name("iss_eugenemalaschuk-source__arch-linter-net__123.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)
g = mod.load_milestones(
    ["v02", "v03", "v04", "v05"],
    [("v02", "v03"), ("v03", "v04"), ("v02", "v05")],
)
assert mod.is_reachable(g, "v02", "v04") is True
assert mod.is_reachable(g, "v04", "v02") is False
assert mod.execution_order(g) == ["v02", "v03", "v04", "v05"]
assert mod.pending_blockers(g, "v04", {"v02"}) == ["v03"]
assert mod.pending_blockers(g, "v04", {"v02", "v03"}) == []

g_d = mod.load_milestones(
    ["hub", "left", "right", "leaf"],
    [("hub", "left"), ("hub", "right"), ("left", "leaf"), ("right", "leaf")],
)
assert mod.is_reachable(g_d, "hub", "leaf") is True
assert mod.execution_order(g_d) == ["hub", "left", "right", "leaf"]

g_c = mod.load_milestones(["a", "b"], [("a", "b"), ("b", "a")])
assert mod.execution_order(g_c) == []
assert mod.pending_blockers(g, "missing", set()) == []
print("ok")
