import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_focusa_254",
    Path(__file__).with_name("iss_Startempire-Wire__focusa__254.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_callgraph(
    [("root", None), ("worker", "root"), ("verify", "worker"), ("settle", "verify")],
    [("root", "worker"), ("worker", "verify"), ("verify", "settle")],
)
assert mod.ancestor_frames(g, "settle") == ["root", "worker", "verify", "settle"]
assert mod.reachable_spawns(g, "root") == ["root", "settle", "verify", "worker"]
assert mod.frontier_frames(g, ["root"]) == ["worker"]
print("ok")
