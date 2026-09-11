import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod570",
    Path(__file__).with_name("iss_amichne__kast__570.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_issue_graph(
    ["KPA-000", "KPA-571", "KPA-572", "KPA-583"],
    [("KPA-571", "KPA-583"), ("KPA-572", "KPA-583")],
    [("KPA-571", "KPA-000"), ("KPA-572", "KPA-000"), ("KPA-583", "KPA-000"), ("KPA-000", None)],
)
levels = mod.dependency_levels(g)
assert levels[0] == ["KPA-000", "KPA-571", "KPA-572"]
assert levels[1] == ["KPA-583"]
assert mod.ready_frontier(g, ["KPA-000"]) == ["KPA-571", "KPA-572"]
assert mod.child_issues(g, "KPA-000") == ["KPA-571", "KPA-572", "KPA-583"]
assert mod.unblock_reach(g, "KPA-571") == ["KPA-583"]

g2 = mod.load_issue_graph(["a", "b"], [("a", "b"), ("b", "a")], [("a", None), ("b", None)])
try:
    mod.dependency_levels(g2)
    assert False, "expected CycleError"
except mod.CycleError:
    pass
print("ok")
