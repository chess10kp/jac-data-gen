import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_irontraffic_147",
    Path(__file__).with_name("iss_ELares__IronTraffic__147.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_compile_graph(
    ["cert", "listener", "route", "table"],
    [("cert", "listener"), ("listener", "route"), ("route", "table")],
)
assert mod.reverse_dependents(g, "cert") == ["cert", "listener", "route", "table"]
assert mod.mark_dirty(g, ["cert"]) == ["cert", "listener", "route", "table"]
assert mod.is_dirty(g, "route")

g2 = mod.load_compile_graph(
    ["upstream", "cluster", "route_a", "route_b"],
    [
        ("upstream", "cluster"),
        ("cluster", "route_a"),
        ("cluster", "route_b"),
    ],
)
assert mod.mark_dirty(g2, ["upstream"]) == [
    "cluster",
    "route_a",
    "route_b",
    "upstream",
]
print("ok")
