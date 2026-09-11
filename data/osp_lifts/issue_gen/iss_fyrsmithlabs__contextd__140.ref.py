import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_fyrsmithlabs__contextd__140",
    Path(__file__).with_name("iss_fyrsmithlabs__contextd__140.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_entity_graph(
    ["caroline", "counseling", "support", "school"],
    [
        ("caroline", "counseling"),
        ("counseling", "support"),
        ("caroline", "school"),
    ],
)
assert mod.entity_neighbors(g, "caroline") == ["counseling", "school"]
assert mod.reachable_entities(g, "caroline", 2) == [
    "caroline",
    "counseling",
    "school",
    "support",
]
assert mod.reachable_entities(g, "caroline", 1) == ["caroline", "counseling", "school"]

g_d = mod.load_entity_graph(
    ["hub", "left", "right", "leaf"],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
)
assert mod.reachable_entities(g_d, "hub", 3) == ["hub", "leaf", "left", "right"]

g_e = mod.load_entity_graph(["solo"], [])
assert mod.reachable_entities(g_e, "missing", 2) == []
assert mod.entity_neighbors(g_e, "missing") == []
print("ok")
