import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_mmtuentertainment__codex-make-me-money__32",
    Path(__file__).with_name("iss_mmtuentertainment__codex-make-me-money__32.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

l = mod.load_ledger(
    ["r1", "r2", "r3", "r4"],
    [("r2", "r1"), ("r3", "r2"), ("r4", "r3")],
    ["r2"],
)
assert mod.lineage_trail(l, "r4") == ["r1", "r2", "r3", "r4"]
assert mod.failure_evidence(l, "r4") == ["r2"]
assert mod.lineage_trail(l, "missing") == []

print("ok")
