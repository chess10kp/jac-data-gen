import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_A1SI_HRMS_42",
    Path(__file__).with_name("iss_A1-Systems-Integrators-LLC__A1SI-HRMS__42.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

TREE = mod.load_projects(
    ["root", "web", "api", "auth", "db"],
    [("root", "web"), ("root", "api"), ("web", "auth"), ("api", "db")],
)
assert mod.get_descendants(TREE, "root") == ["api", "auth", "db", "web"]
assert mod.child_count(TREE, "root") == 2
assert mod.archive_project(TREE, "web") == ["auth", "web"]
assert mod.active_projects(TREE) == ["api", "db", "root"]

assert mod.get_descendants(TREE, "missing") == []
print("ok")
