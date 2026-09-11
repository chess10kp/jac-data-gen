import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_eugenemalaschuk-source__arch-linter-net__461.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_analysis_graph(
    ["root", "app", "tests"],
    [("root", None), ("app", "root"), ("tests", "app")],
    [("eval", ["graph", "load"]), ("graph", ["load"]), ("load", [])],
)
assert mod.project_ancestors(g, "tests") == ["app", "root"]
assert mod.phases_reachable_from(g, ["eval"]) == ["eval", "graph", "load"]
print("ok")
