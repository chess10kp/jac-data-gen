import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_ouroboros_276",
    Path(__file__).with_name("iss_NobuData__ouroboros__276.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

b = mod.load_ticket_board(
    ["OTA-1", "OTA-2", "OTA-3"],
    [("OTA-1", "OTA-2"), ("OTA-2", "OTA-3")],
)
assert not mod.has_dependency_cycle(b)
assert mod.push_order(b) == ["OTA-1", "OTA-2", "OTA-3"]

c = mod.load_ticket_board(["A", "B"], [("A", "B"), ("B", "A")])
assert mod.has_dependency_cycle(c)
assert mod.push_order(c) == []
print("ok")
