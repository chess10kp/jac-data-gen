import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_method_72",
    Path(__file__).with_name("iss_flyingrobots__method__72.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_issue_graph(
    [1, 2, 3, 4, 5],
    [(1, 2), (2, 3), (1, 4), (4, 5)],
    open_issues=[1, 2, 3, 4, 5],
)
assert mod.frontier_issues(g) == [1]
assert mod.detect_dependency_cycles(g) == []
assert mod.critical_path_depth(g, 5) == 2

g2 = mod.load_issue_graph([10, 20], [(10, 20), (20, 10)])
assert mod.detect_dependency_cycles(g2) == [(20, 10)]

g3 = mod.load_issue_graph([1, 2, 3], [(1, 3)], open_issues=[1, 2, 3])
assert mod.frontier_issues(g3) == [1, 2]
print("ok")
