import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_ccb_1594",
    Path(__file__).with_name("iss_SzeChunYiu__ccb-testbeam__1594.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_audit_graph([
    ("raw_cardinality", None),
    ("selection", "raw_cardinality"),
    ("timing", "selection"),
    ("pid", "timing"),
])
assert mod.active_claims(g) == ["pid", "raw_cardinality", "selection", "timing"]
assert mod.mark_failed(g, "selection") == ["pid", "selection", "timing"]
assert mod.active_claims(g) == ["raw_cardinality"]
assert mod.upstream_chain(g, "pid") == ["raw_cardinality", "selection", "timing", "pid"]
print("ok")
