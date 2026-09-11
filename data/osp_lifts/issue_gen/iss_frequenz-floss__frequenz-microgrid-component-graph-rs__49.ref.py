import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_frequenz_floss_49",
    Path(__file__).with_name(
        "iss_frequenz-floss__frequenz-microgrid-component-graph-rs__49.py"
    ),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_meter_graph(
    ["m1", "m2", "m3", "m4"],
    [("m1", "m2"), ("m2", "m3"), ("m1", "m4")],
)
assert mod.prune_topmost_candidates(g, ["m1", "m2", "m3"]) == ["m1"]
assert mod.prune_topmost_candidates(g, ["m2", "m3", "m4"]) == ["m2", "m4"]

g_d = mod.load_meter_graph(
    ["hub", "left", "right", "leaf"],
    [("hub", "left"), ("hub", "right"), ("left", "leaf"), ("right", "leaf")],
)
assert sorted(mod.prune_topmost_candidates(g_d, ["left", "right", "leaf"])) == [
    "left",
    "right",
]
print("ok")
