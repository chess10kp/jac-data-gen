import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_elgansayer__elgl__7035",
    Path(__file__).with_name("iss_elgansayer__elgl__7035.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_factory(
    [("cut", "weld"), ("weld", "paint"), ("prep", "cut")],
    ["weld"],
)
assert mod.ready_steps(g) == ["prep"]
assert mod.locked_reachable(g, "prep") == ["weld"]
assert mod.has_lock_cycle(g) is False

g_cycle = mod.load_factory([("a", "b"), ("b", "c"), ("c", "a")], [])
assert mod.has_lock_cycle(g_cycle) is True

g_diamond = mod.load_factory(
    [("hub", "left"), ("hub", "right"), ("left", "sink"), ("right", "sink")],
    ["sink"],
)
assert mod.locked_reachable(g_diamond, "hub") == ["sink"]
print("ok")
