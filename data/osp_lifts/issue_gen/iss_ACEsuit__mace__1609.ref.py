import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_mace_1609",
    Path(__file__).with_name("iss_ACEsuit__mace__1609.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_governance(
    ["GOV-1", "GOV-2a", "GOV-2b", "REL-2"],
    [("GOV-1", "GOV-2a"), ("GOV-1", "GOV-2b"), ("GOV-2a", "REL-2"), ("GOV-2b", "REL-2")],
)
assert mod.unblock_order(g) == ["GOV-1", "GOV-2a", "GOV-2b", "REL-2"]
assert mod.transitive_blockers(g, "REL-2") == ["GOV-1", "GOV-2a", "GOV-2b"]
assert mod.has_cycle(g) is False
print("ok")
