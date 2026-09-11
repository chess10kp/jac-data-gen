import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_ysysimon__YOrch__10.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_task_graph(["A", "B", "C", "D"], [("B", "A"), ("C", "A"), ("D", "B"), ("D", "C")])
assert mod.compile_plan(g) == ["A", "B", "C", "D"]
assert mod.ready_after(g, ["A"]) == ["B", "C"]
print("ok")
