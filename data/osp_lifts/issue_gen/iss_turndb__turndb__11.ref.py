import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_turndb_11",
    Path(__file__).with_name("iss_turndb__turndb__11.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_gate(
    ["ci", "release", "docs", "npm"],
    [("ci", "release"), ("release", "npm"), ("npm", "docs")],
    {"ci": "FIX", "release": "STATE", "npm": "open", "docs": "open"},
)
assert mod.downstream_items(g, "release") == ["docs", "npm"]
assert mod.blocked_by_state(g, "release", ["open"]) == ["docs", "npm"]
assert mod.unresolved_refs(g) == []
print("ok")
