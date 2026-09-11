import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_rh_174",
    Path(__file__).with_name("iss_OVVO-Financial__RH_Lean__174.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_theorems([
    ("SquarePrefix", None),
    ("MertensEnergy", "SquarePrefix"),
    ("ClassicalMertens", "MertensEnergy"),
    ("RHStatement", "ClassicalMertens"),
])
assert mod.proof_chain(g, "RHStatement") == [
    "SquarePrefix", "MertensEnergy", "ClassicalMertens", "RHStatement"
]
assert mod.downstream_theorems(g, "MertensEnergy") == [
    "ClassicalMertens", "MertensEnergy", "RHStatement"
]
print("ok")
