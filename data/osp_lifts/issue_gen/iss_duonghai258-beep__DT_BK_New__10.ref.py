import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_dtbk_10",
    Path(__file__).with_name("iss_duonghai258-beep__DT_BK_New__10.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_arch_graph(
    ["domain", "application", "infrastructure", "gui"],
    {"domain": 0, "application": 1, "infrastructure": 2, "gui": 3},
    [
        ("application", "domain"),
        ("infrastructure", "application"),
        ("gui", "application"),
    ],
)
assert mod.detect_cycles(g) == []
assert mod.reverse_layer_violations(g) == []
assert mod.upstream_closure(g, "gui") == ["application", "domain", "gui"]

g_bad = mod.load_arch_graph(
    ["a", "b"],
    {"a": 0, "b": 1},
    [("a", "b"), ("b", "a")],
)
assert mod.detect_cycles(g_bad) == [("b", "a")]
print("ok")
