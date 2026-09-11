import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_05798__pytest-git-selector__19",
    Path(__file__).with_name("iss_05798__pytest-git-selector__19.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)
g = mod.load_import_graph(
    ["test_a.py", "test_b.py", "lib/x.py", "lib/y.py", "util.py"],
    [
        ("test_a.py", "lib/x.py"),
        ("test_b.py", "lib/y.py"),
        ("lib/x.py", "util.py"),
        ("lib/y.py", "util.py"),
    ],
    ["test_a.py", "test_b.py"],
)
assert mod.tests_for_changes(g, ["util.py"]) == ["test_a.py", "test_b.py"]
assert mod.tests_for_changes(g, ["lib/x.py"]) == ["test_a.py"]
assert mod.tests_for_changes(g, ["ghost.py"]) == []

g_d = mod.load_import_graph(
    ["t1.py", "t2.py", "core.py", "left.py", "right.py"],
    [
        ("t1.py", "left.py"),
        ("t2.py", "right.py"),
        ("left.py", "core.py"),
        ("right.py", "core.py"),
    ],
    ["t1.py", "t2.py"],
)
assert mod.tests_for_changes(g_d, ["core.py"]) == ["t1.py", "t2.py"]
print("ok")
