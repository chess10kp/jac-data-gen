import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_chittihq__pintail__29",
    Path(__file__).with_name("iss_chittihq__pintail__29.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

s = mod.load_replica(
    ["orders", "items", "audit"],
    [("orders", "items"), ("items", "audit")],
    {"orders": ["o1"], "items": ["i1", "i2"], "audit": ["a1"]},
)
assert mod.active_rows(s, "orders") == ["o1"]
assert mod.cascade_tombstone(s, "orders", "o1") == [
    ("audit", "a1"),
    ("items", "i1"),
    ("items", "i2"),
    ("orders", "o1"),
]
assert mod.active_rows(s, "orders") == []
assert mod.active_rows(s, "items") == []

try:
    mod.cascade_tombstone(s, "orders", "ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass

print("ok")
