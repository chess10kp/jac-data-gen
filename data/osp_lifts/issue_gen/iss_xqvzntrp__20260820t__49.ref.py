import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_exec_49",
    Path(__file__).with_name("iss_xqvzntrp__20260820t__49.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_execution(
    ["scalar", "filter", "project", "join"],
    [("scalar", "filter"), ("filter", "project"), ("scalar", "join")],
    {"project": "out_project"},
)
assert mod.execution_order(g) == ["scalar", "filter", "join", "project"]
assert mod.upstream_closure(g, "project") == ["filter", "scalar"]
assert mod.bind_output(g, "project") == "out_project"
print("ok")
