import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_DevilTea__deviltea-labs__13",
    Path(__file__).with_name("iss_DevilTea__deviltea-labs__13.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_widget_graph(
    ["survey", "duration", "budget", "recommend"],
    [
        ("survey", "duration"),
        ("survey", "budget"),
        ("duration", "recommend"),
    ],
)
assert mod.transitive_deps(g, "survey") == [
    "budget",
    "duration",
    "recommend",
    "survey",
]
assert mod.compile_blockers(g, "recommend") == ["recommend", "duration", "survey"]
assert mod.compile_blockers(g, "survey") == ["survey"]

g_diamond = mod.load_widget_graph(
    ["root", "left", "right", "leaf"],
    [("right", "leaf"), ("root", "left"), ("left", "leaf"), ("root", "right")],
)
assert mod.transitive_deps(g_diamond, "root") == ["leaf", "left", "right", "root"]

g_cycle = mod.load_widget_graph(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert mod.compile_blockers(g_cycle, "a") == ["a", "c", "b"]
assert mod.transitive_deps(g_cycle, "b") == ["a", "b", "c"]

assert mod.transitive_deps(g, "missing") == []
assert mod.compile_blockers(g, "missing") == []
print("ok")
