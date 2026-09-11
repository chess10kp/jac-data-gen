import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_moduletester_18",
    Path(__file__).with_name("iss_Codra-Ingenierie-Informatique__ModuleTester__18.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_test_graph(
    ["setup", "unit", "integration"],
    [("setup", "unit"), ("unit", "integration")],
)
assert mod.runnable_tests(g) == ["setup"]
mod.mark_passed(g, "setup")
assert mod.runnable_tests(g) == ["unit"]

g2 = mod.load_test_graph(
    ["setup", "integration", "report"],
    [("setup", "integration"), ("integration", "report")],
)
assert mod.mark_failed(g2, "setup") == ["integration", "report"]

g_cycle = mod.load_test_graph(["a", "b"], [("a", "b"), ("b", "a")])
assert mod.detect_test_cycles(g_cycle) == [("a", "b")]
print("ok")
