import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_tokio_10",
    Path(__file__).with_name("iss_dsyme__tokio__10.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_task_graph(
    ["rt", "worker", "io", "timer"],
    [("rt", "worker"), ("rt", "io"), ("worker", "timer")],
)
assert mod.reachable_tasks(g, "rt") == ["io", "rt", "timer", "worker"]
assert mod.spawn_depth_within(g, "rt", 3)
assert mod.orphan_tasks(g, ["rt"]) == []

g_diamond = mod.load_task_graph(
    ["hub", "left", "right", "leaf"],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
)
assert mod.reachable_tasks(g_diamond, "hub") == ["hub", "leaf", "left", "right"]
print("ok")
