import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_99x__xianix-team__3",
    Path(__file__).with_name("iss_99x__xianix-team__3.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_module_graph(
    ["api", "core", "db", "ui", "auth"],
    [("ui", "api"), ("api", "core"), ("api", "auth"), ("core", "db")],
)
assert mod.impacted_modules(g, ["db"], 3) == ["api", "core", "ui"]
assert mod.direct_dependents(g, "core") == ["api"]
assert mod.dependency_closure(g, "ui") == ["api", "auth", "core", "db"]

g_d = mod.load_module_graph(
    ["hub", "left", "right", "sink"],
    [("hub", "left"), ("hub", "right"), ("left", "sink"), ("right", "sink")],
)
assert mod.impacted_modules(g_d, ["sink"], 2) == ["hub", "left", "right"]
print("ok")
