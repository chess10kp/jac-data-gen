import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_EffortlessMetrics__perl-lsp-swarm__8769",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__8769.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_module_graph(
    ["A", "B", "C", "D"],
    [("A", "B"), ("B", "C"), ("A", "D")],
)
assert mod.compile_reach(g, "A") == ["A", "B", "C", "D"]
assert mod.compile_levels(g, "A") == [["A"], ["B", "D"], ["C"]]

g_d = mod.load_module_graph(
    ["hub", "left", "right", "leaf"],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
)
assert mod.compile_reach(g_d, "hub") == ["hub", "leaf", "left", "right"]

g_c = mod.load_module_graph(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert mod.compile_reach(g_c, "a") == ["a", "b", "c"]

g_e = mod.load_module_graph(["solo"], [])
assert mod.compile_reach(g_e, "missing") == []
assert mod.compile_levels(g_e, "missing") == []
print("ok")
