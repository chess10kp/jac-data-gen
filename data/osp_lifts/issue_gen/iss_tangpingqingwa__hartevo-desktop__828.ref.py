import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_tangpingqingwa__hartevo-desktop__828",
    Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

DIAMOND = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")]
CYCLE = [("a", "b"), ("b", "c"), ("c", "a")]
LINE = [("r", "s"), ("s", "t")]
STAR = [("hub", f"f{i}") for i in range(6)]

status, digests = mod.governed_reach("a", DIAMOND, hop_budget=2, row_cap=64)
assert status == "PRESENT"
assert digests == sorted(mod.node_digest(n) for n in ["a", "b", "c", "d"])
assert mod.within_budget("a", DIAMOND, hop_budget=2, row_cap=64) is True

status, digests = mod.governed_reach("a", CYCLE, hop_budget=10, row_cap=64)
assert status == "PRESENT"
assert len(digests) == 3

status, digests = mod.governed_reach("r", LINE, hop_budget=1, row_cap=64)
assert status == "PRESENT"
assert digests == sorted(mod.node_digest(n) for n in ["r", "s"])

status, digests = mod.governed_reach("hub", STAR, hop_budget=4, row_cap=3)
assert status == "PARTIAL"
assert len(digests) == 3
assert mod.within_budget("hub", STAR, hop_budget=4, row_cap=3) is False

assert mod.governed_reach("missing", LINE) == ("EMPTY", [])
assert mod.within_budget("missing", LINE) is False
print("ok")
