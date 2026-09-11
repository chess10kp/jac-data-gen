"""Reference harness for iss_Ashutosh-Malve__sentinel-rbac__7."""
import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Ashutosh-Malve__sentinel-rbac__7.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

reg = mod.load_org_registry(
    [("tenant", None), ("hq", "tenant"), ("dept", "hq"), ("team", "dept")],
)
assert mod.ancestor_path(reg, "team") == ["tenant", "hq", "dept", "team"]
assert mod.materialized_path(reg, "team") == "/tenant/hq/dept/team"
assert mod.org_depth(reg, "team") == 3
assert mod.ancestor_path(reg, "tenant") == ["tenant"]
assert mod.ancestor_path(reg, "ghost") == []

print("iss_Ashutosh-Malve__sentinel-rbac__7 ref OK")
