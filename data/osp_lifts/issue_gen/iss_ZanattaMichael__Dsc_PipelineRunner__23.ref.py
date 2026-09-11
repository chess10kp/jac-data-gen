import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_ZanattaMichael__Dsc_PipelineRunner__23",
    Path(__file__).with_name("iss_ZanattaMichael__Dsc_PipelineRunner__23.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)
g = mod.load_resources(["A", "B", "C"], {"B": ["A"], "C": ["B"]})
assert mod.sort_depends_on(g) == ["A", "B", "C"]

g_d = mod.load_resources(
    ["hub", "left", "right", "leaf"],
    {"left": ["hub"], "right": ["hub"], "leaf": ["left", "right"]},
)
assert mod.sort_depends_on(g_d) == ["hub", "left", "right", "leaf"]

g_c = mod.load_resources(["X", "Y"], {"X": ["Y"], "Y": ["X"]})
try:
    mod.sort_depends_on(g_c)
    raise AssertionError("cycle expected")
except ValueError as e:
    assert "cycle" in str(e)

try:
    mod.load_resources(["A"], {"A": ["missing"]})
    raise AssertionError("missing ref expected")
except KeyError:
    pass
print("ok")
