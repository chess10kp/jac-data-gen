import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_timbrinded__shapelang__105.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_effect_graph(
    ["main", "wrap", "io"],
    [("main", "wrap"), ("wrap", "io")],
    [("io", "read"), ("main", "log")],
)
assert mod.reachable_effects(g, "main") == ["log", "read"]
assert mod.missing_effects(g, "main", ["log"]) == ["read"]
assert mod.has_unknown_reachable(g, "main") is False

g2 = mod.load_effect_graph(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c")],
    [("c", "net")],
    unknown=["b"],
)
assert mod.has_unknown_reachable(g2, "a") is True
assert mod.reachable_effects(g2, "a") == []
print("ok")
