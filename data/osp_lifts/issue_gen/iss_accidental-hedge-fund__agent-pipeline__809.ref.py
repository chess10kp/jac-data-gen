import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_accidental-hedge-fund__agent-pipeline__809",
    Path(__file__).with_name("iss_accidental-hedge-fund__agent-pipeline__809.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_symbol_graph(
    ["main", "helper", "util", "sink"],
    [("main", "helper"), ("helper", "util"), ("util", "sink"), ("main", "sink")],
)
assert mod.call_paths(g, "main", "sink", 4) == ["helper", "main", "sink", "util"]
assert mod.reachable_symbols(g, "main", 2) == ["helper", "sink", "util"]
assert mod.has_cycle(g) is False

g_c = mod.load_symbol_graph(["a", "b", "c"], [("a", "b"), ("b", "c"), ("c", "a")])
assert mod.has_cycle(g_c) is True
print("ok")
