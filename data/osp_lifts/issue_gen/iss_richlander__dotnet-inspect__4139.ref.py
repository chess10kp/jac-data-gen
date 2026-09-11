import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_richlander_4139",
    Path(__file__).with_name("iss_richlander__dotnet-inspect__4139.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

cg = mod.load_call_graph(
    ["Main", "Helper", "Util", "Leaf"],
    [("Main", "Helper"), ("Helper", "Util"), ("Main", "Leaf")],
)
assert mod.reachable_members(cg, "Main") == ["Helper", "Leaf", "Main", "Util"]
assert mod.callers_of(cg, "Util") == ["Helper"]

cg_d = mod.load_call_graph(
    ["hub", "left", "right", "bot"],
    [("right", "bot"), ("hub", "left"), ("left", "bot"), ("hub", "right")],
)
assert mod.reachable_members(cg_d, "hub") == ["bot", "hub", "left", "right"]
print("ok")
