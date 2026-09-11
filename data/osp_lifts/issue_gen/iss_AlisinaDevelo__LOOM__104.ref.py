import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_AlisinaDevelo__LOOM__104",
    Path(__file__).with_name("iss_AlisinaDevelo__LOOM__104.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_provenance(
    ["capture", "snapshot", "source", "root"],
    [("capture", "snapshot"), ("snapshot", "source"), ("source", "root")],
)
assert mod.upstream_lineage(g, "capture", 2) == ["capture", "snapshot", "source"]
assert mod.within_bound(g, "capture", 3) is True
assert mod.within_bound(g, "capture", 2) is False
assert mod.upstream_lineage(g, "missing", 3) == []

print("ok")
