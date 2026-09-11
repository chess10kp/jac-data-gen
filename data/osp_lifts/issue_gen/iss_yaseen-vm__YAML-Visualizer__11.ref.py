import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_yaseen-vm__YAML-Visualizer__11.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_services(["api", "db"], [("api", "db"), ("api", "ghost")])
assert mod.missing_deps(g) == ["ghost"]
assert mod.has_cycle(g) is False

g2 = mod.load_services(["a", "b", "c"], [("a", "b"), ("b", "c"), ("c", "a")])
assert mod.has_cycle(g2) is True
print("ok")
