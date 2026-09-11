import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_skills_48",
    Path(__file__).with_name("iss_jhonDoe15__skills__48.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_plan_graph(
    ["t1", "t2", "t3", "t4"],
    [("t1", "t3"), ("t2", "t3"), ("t3", "t4")],
    ["t1"],
)
assert mod.frontier(g) == ["t2"]
mod.mark_done(g, "t2")
assert mod.frontier(g) == ["t3"]

g_cycle = mod.load_plan_graph(["a", "b"], [("a", "b"), ("b", "a")], [])
assert mod.detect_plan_cycles(g_cycle) == [("a", "b")]
print("ok")
