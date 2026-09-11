import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_Ankit6149__hardware-studio__40",
    Path(__file__).with_name("iss_Ankit6149__hardware-studio__40.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_product_graph(
    ["assy", "pcb", "fw", "req"],
    [("assy", "pcb"), ("pcb", "fw")],
    [("fw", "req")],
)
assert mod.impact_set(g, "assy") == ["assy", "fw", "pcb", "req"]
assert mod.ancestor_trace(g, "fw") == ["fw", "pcb", "assy"]

g_d = mod.load_product_graph(
    ["hub", "left", "right", "leaf"],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    [],
)
assert mod.impact_set(g_d, "hub") == ["hub", "leaf", "left", "right"]

g_c = mod.load_product_graph(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
    [],
)
assert mod.ancestor_trace(g_c, "a") == ["a", "c", "b"]

g_e = mod.load_product_graph(["solo"], [], [])
assert mod.impact_set(g_e, "missing") == []
assert mod.ancestor_trace(g_e, "missing") == []
print("ok")
