import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_snissn__music__1",
    Path(__file__).with_name("iss_snissn__music__1.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

GRAPH = mod.load_issue_graph(
    ["2", "3", "4", "5", "6", "7", "8"],
    [
        ("2", "3"), ("2", "5"), ("2", "6"),
        ("3", "4"), ("3", "7"), ("4", "6"), ("4", "7"), ("4", "8"),
        ("5", "8"), ("6", "8"), ("7", "8"),
    ],
)
assert mod.critical_path(GRAPH, "8") == ["2", "3", "4", "5", "6", "7", "8"]
assert mod.unblocked(GRAPH, []) == ["2"]
assert mod.unblocked(GRAPH, ["2"]) == ["3", "5"]
assert mod.unblocked(GRAPH, ["2", "3", "4", "5", "6", "7"]) == ["8"]

assert mod.critical_path(GRAPH, "missing") == []
print("ok")
