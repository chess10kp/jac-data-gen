import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_spring_1",
    Path(__file__).with_name("iss_guillipa1993__spring-security__1.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_build_graph(
    ["core", "config", "web", "test"],
    [("core", "config"), ("config", "web"), ("core", "test")],
)
assert mod.detect_build_cycles(g) == []
assert mod.build_order_depth(g, "web") == 2

g2 = mod.load_build_graph(["a", "b"], [("a", "b"), ("b", "a")])
assert mod.detect_build_cycles(g2) == [("b", "a")]
print("ok")
