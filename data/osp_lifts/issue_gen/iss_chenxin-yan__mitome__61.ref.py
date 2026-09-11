import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_mitome_61",
    Path(__file__).with_name("iss_chenxin-yan__mitome__61.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_extension_graph(
    ["browser", "scraper", "screenshot"],
    [("browser", "scraper"), ("browser", "screenshot")],
    {"browser": ["page"], "scraper": ["html"]},
)
assert mod.resolve_load_order(g) == ["browser", "scraper", "screenshot"]
assert mod.transitive_dependencies(g, "screenshot") == ["browser"]
assert mod.detect_extension_cycles(g) == []

c = mod.load_extension_graph(["a", "b"], [("a", "b"), ("b", "a")])
assert mod.detect_extension_cycles(c) == [("b", "a")]
assert mod.resolve_load_order(c) == []
print("ok")
