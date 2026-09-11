import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_NousResearch__hermes-agent__89493",
    Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

HIER = [
    "portfolio",
    "ws_a",
    "ws_b",
    "project",
    "epic",
]
PARENTS = [
    ("portfolio", "ws_a"),
    ("portfolio", "ws_b"),
    ("ws_a", "project"),
    ("ws_b", "project"),
    ("project", "epic"),
]
DEPS = [("ws_a", "project")]
REFS = [("epic", "ws_a")]

g = mod.build_roadmap(HIER, PARENTS, DEPS, REFS)

assert mod.roadmap_children(g, "portfolio") == ["ws_a", "ws_b"]
assert mod.roadmap_children(g, "project") == ["epic"]
assert mod.roadmap_children(g, "ghost") == []
assert mod.roadmap_closure(g, "portfolio") == ["epic", "project", "ws_a", "ws_b"]
assert mod.roadmap_closure(g, "epic") == []
assert mod.roadmap_closure(g, "ghost") == []
assert mod.has_hierarchy_cycle(g) is False

cyc = mod.build_roadmap(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
    [],
    [],
)
assert mod.has_hierarchy_cycle(cyc) is True
assert mod.roadmap_closure(cyc, "a") == ["b", "c"]

adv = mod.build_roadmap(
    ["r", "a", "b", "c", "d"],
    [("r", "b"), ("r", "a"), ("a", "c"), ("b", "c"), ("c", "d")],
    [],
    [],
)
assert mod.roadmap_closure(adv, "r") == ["a", "b", "c", "d"]
print("ok")
