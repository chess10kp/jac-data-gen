import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_bigstardust_332",
    Path(__file__).with_name("iss_Saanvi51__bigstardust-workspace__332.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_study_graph(
    ["a", "b", "c", "d", "e"],
    [("a", "b"), ("b", "c"), ("d", "e")],
)
assert mod.connected_components(g) == [["a", "b", "c"], ["d", "e"]]
assert mod.component_count(g) == 2

g_d = mod.load_study_graph(
    ["hub", "left", "right", "bot"],
    [("right", "bot"), ("hub", "left"), ("left", "bot"), ("hub", "right")],
)
assert mod.connected_components(g_d) == [["bot", "hub", "left", "right"]]
print("ok")
