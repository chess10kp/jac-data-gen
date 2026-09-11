import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_DependencyTrack__dependency-track__3452",
    Path(__file__).with_name("iss_DependencyTrack__dependency-track__3452.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_dep_graph(
    ["proj", "lib", "util", "leaf"],
    [("proj", "lib"), ("lib", "util"), ("util", "leaf")],
)
assert mod.forward_closure(g, "proj") == ["leaf", "lib", "proj", "util"]
assert mod.reverse_introducers(g, "leaf") == ["leaf", "lib", "proj", "util"]

g_d = mod.load_dep_graph(
    ["hub", "left", "right", "leaf"],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
)
assert mod.forward_closure(g_d, "hub") == ["hub", "leaf", "left", "right"]

g_c = mod.load_dep_graph(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert mod.forward_closure(g_c, "a") == ["a", "b", "c"]
assert mod.reverse_introducers(g_c, "b") == ["a", "b", "c"]

g_e = mod.load_dep_graph(["solo"], [])
assert mod.forward_closure(g_e, "missing") == []
assert mod.reverse_introducers(g_e, "missing") == []
print("ok")
