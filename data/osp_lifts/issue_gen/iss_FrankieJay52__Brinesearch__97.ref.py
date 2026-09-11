"""Reference harness for iss_FrankieJay52__Brinesearch__97."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_FrankieJay52__Brinesearch__97.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

g = _mod.load_road_graph(
    ["r1", "r2", "r3", "r4"],
    ["j1", "j2", "j3"],
    [("r1", "j1"), ("r2", "j1"), ("r2", "j2"), ("r3", "j2"), ("r4", "j3")],
    junction_link_edges=[("j2", "j3")],
)
assert _mod.connected_roads(g, "r1") == ["r2", "r3", "r4"]
assert _mod.junction_reach(g, "j1") == ["j2", "j3", "r1", "r2", "r3", "r4"]
assert _mod.road_component_size(g, "r1") == 4
assert _mod.connected_roads(g, "missing") == []

print("iss_FrankieJay52__Brinesearch__97 ref OK")
