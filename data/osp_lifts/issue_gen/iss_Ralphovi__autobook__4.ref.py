import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_Ralphovi__autobook__4",
    Path(__file__).with_name("iss_Ralphovi__autobook__4.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_booking_store(
    [("weekly", ["w1", "w2"]), ("w1", []), ("w2", [])],
    [("w1", "w2")],
)
assert mod.instance_lineage(g, "weekly") == ["w1", "w2", "weekly"]
assert mod.schedule_order(g) == ["weekly", "w1", "w2"]
assert mod.expand_occurrences(g, "weekly", 2) == ["weekly", "w1"]

g2 = mod.load_booking_store(
    [("hub", ["a", "b"]), ("a", ["leaf"]), ("b", ["leaf"]), ("leaf", [])],
    [("hub", "a"), ("hub", "b")],
)
assert mod.instance_lineage(g2, "hub") == ["a", "b", "hub", "leaf"]
assert mod.expand_occurrences(g2, "hub", 10) == ["hub", "a", "b", "leaf"]
assert mod.instance_lineage(g2, "ghost") == []
print("ok")
