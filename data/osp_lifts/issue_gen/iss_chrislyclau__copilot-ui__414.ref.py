import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_chrislyclau__copilot-ui__414",
    Path(__file__).with_name("iss_chrislyclau__copilot-ui__414.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)
g = mod.load_planner(
    ["epic", "a", "b", "c"],
    [("a", "epic"), ("b", "epic"), ("c", "b")],
    [("a", "b")],
)
st = {"a": "done", "b": "todo", "c": "todo", "epic": "todo"}
assert mod.is_blocked(g, "b", st) is False
mod.add_dependency(g, "b", "c")
assert mod.is_blocked(g, "c", st) is True
assert mod.subtree_tasks(g, "epic") == ["a", "b", "c", "epic"]
assert mod.dependent_closure(g, "a") == ["a", "b", "c"]

g2 = mod.load_planner(["x", "y", "z"], [], [])
mod.add_dependency(g2, "x", "y")
try:
    mod.add_dependency(g2, "y", "x")
    raise AssertionError("cycle expected")
except ValueError as e:
    assert "cycle" in str(e)

g_d = mod.load_planner(
    ["hub", "left", "right", "leaf"],
    [("left", "hub"), ("right", "hub"), ("leaf", "left"), ("leaf", "right")],
    [],
)
assert mod.subtree_tasks(g_d, "hub") == ["hub", "leaf", "left", "right"]
assert mod.is_blocked(g_d, "hub", {}, read_error=True) is True
mod.remove_dependency(g, "b", "c")
assert mod.is_blocked(g, "c", st) is False
print("ok")
